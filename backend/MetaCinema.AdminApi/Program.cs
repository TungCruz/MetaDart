using FirebaseAdmin;
using FirebaseAdmin.Auth;
using Google.Apis.Auth.OAuth2;
using Google.Cloud.Firestore;

const string DefaultPassword = "123456";
const int MaxAvatarBytes = 700 * 1024;

var builder = WebApplication.CreateBuilder(args);
var projectId = builder.Configuration["Firebase:ProjectId"]
    ?? throw new InvalidOperationException("Missing Firebase:ProjectId configuration.");

var credential = GoogleCredential.GetApplicationDefault();
var firebaseApp = FirebaseApp.Create(new AppOptions
{
    Credential = credential,
    ProjectId = projectId,
});
var firebaseAuth = FirebaseAuth.GetAuth(firebaseApp);
var firestore = FirestoreDb.Create(projectId);

if (args.Contains("--check-firebase"))
{
    await firebaseAuth.GetUserByEmailAsync("admin@metacinema.app");
    await firestore.Collection("users").Limit(1).GetSnapshotAsync();
    Console.WriteLine("Firebase Authentication and Firestore connection: OK");
    return;
}

builder.Services.AddSingleton(firebaseAuth);
builder.Services.AddSingleton(firestore);
builder.Services.AddCors(options => options.AddDefaultPolicy(policy =>
    policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod()));

var app = builder.Build();
app.UseCors();

app.MapGet("/health", () => Results.Ok(new { status = "ok" }));

app.MapGet("/api/admin/users", async (
    HttpRequest httpRequest,
    FirebaseAuth auth,
    FirestoreDb db) =>
{
    var access = await RequireAdminAsync(httpRequest, auth, db);
    if (access.Error is not null) return access.Error;

    var snapshot = await db.Collection("users").GetSnapshotAsync();
    return Results.Ok(new { count = snapshot.Count });
});

app.MapPost("/api/admin/users", async (
    HttpRequest httpRequest,
    CreateUserRequest request,
    FirebaseAuth auth,
    FirestoreDb db) =>
{
    var access = await RequireAdminAsync(httpRequest, auth, db);
    if (access.Error is not null) return access.Error;

    var validation = ValidateUser(request.Name, request.Email, request.Phone, request.Age);
    if (validation is not null) return BadRequest(validation);
    var avatar = DecodeAvatar(request.AvatarBase64);
    if (avatar.Error is not null) return BadRequest(avatar.Error);

    UserRecord? createdUser = null;
    try
    {
        createdUser = await auth.CreateUserAsync(new UserRecordArgs
        {
            Email = request.Email.Trim().ToLowerInvariant(),
            Password = DefaultPassword,
            DisplayName = request.Name.Trim(),
            Disabled = false,
        });

        var batch = db.StartBatch();
        var userRef = db.Collection("users").Document(createdUser.Uid);
        batch.Set(userRef, new Dictionary<string, object?>
        {
            ["id"] = createdUser.Uid,
            ["name"] = request.Name.Trim(),
            ["email"] = request.Email.Trim().ToLowerInvariant(),
            ["phone"] = request.Phone.Trim(),
            ["age"] = request.Age,
            ["role"] = "user",
            ["status"] = "active",
            ["emailVerified"] = false,
            ["mustChangePassword"] = true,
            ["createdAt"] = FieldValue.ServerTimestamp,
            ["updatedAt"] = FieldValue.ServerTimestamp,
        });
        if (avatar.Bytes is not null)
        {
            batch.Set(db.Collection("userAvatars").Document(createdUser.Uid),
                AvatarData(avatar.Bytes, request.AvatarContentType));
        }
        await batch.CommitAsync();
        return Results.Created($"/api/admin/users/{createdUser.Uid}", new
        {
            id = createdUser.Uid,
            defaultPassword = DefaultPassword,
            mustChangePassword = true,
        });
    }
    catch (Exception exception)
    {
        if (createdUser is not null)
        {
            try { await auth.DeleteUserAsync(createdUser.Uid); }
            catch { /* Best-effort rollback. */ }
        }
        return FirebaseFailure(exception);
    }
});

app.MapPut("/api/admin/users/{uid}", async (
    string uid,
    HttpRequest httpRequest,
    UpdateUserRequest request,
    FirebaseAuth auth,
    FirestoreDb db) =>
{
    var access = await RequireAdminAsync(httpRequest, auth, db);
    if (access.Error is not null) return access.Error;

    var validation = ValidateUser(request.Name, request.Email, request.Phone, request.Age);
    if (validation is not null) return BadRequest(validation);
    var avatar = DecodeAvatar(request.AvatarBase64);
    if (avatar.Error is not null) return BadRequest(avatar.Error);

    try
    {
        await auth.UpdateUserAsync(new UserRecordArgs
        {
            Uid = uid,
            Email = request.Email.Trim().ToLowerInvariant(),
            DisplayName = request.Name.Trim(),
        });

        var batch = db.StartBatch();
        batch.Update(db.Collection("users").Document(uid), new Dictionary<string, object?>
        {
            ["id"] = uid,
            ["name"] = request.Name.Trim(),
            ["email"] = request.Email.Trim().ToLowerInvariant(),
            ["phone"] = request.Phone.Trim(),
            ["age"] = request.Age,
            ["updatedAt"] = FieldValue.ServerTimestamp,
        });
        var avatarRef = db.Collection("userAvatars").Document(uid);
        if (request.RemoveAvatar)
            batch.Delete(avatarRef);
        else if (avatar.Bytes is not null)
            batch.Set(avatarRef, AvatarData(avatar.Bytes, request.AvatarContentType));
        await batch.CommitAsync();
        return Results.Ok(new { id = uid });
    }
    catch (Exception exception)
    {
        return FirebaseFailure(exception);
    }
});

app.MapPatch("/api/admin/users/{uid}/status", async (
    string uid,
    HttpRequest httpRequest,
    StatusRequest request,
    FirebaseAuth auth,
    FirestoreDb db) =>
{
    var access = await RequireAdminAsync(httpRequest, auth, db);
    if (access.Error is not null) return access.Error;
    if (uid == access.Token!.Uid) return BadRequest("Không thể tự khóa tài khoản admin đang đăng nhập.");
    if (request.Status is not ("active" or "disabled")) return BadRequest("Trạng thái không hợp lệ.");

    try
    {
        var disabled = request.Status == "disabled";
        await auth.UpdateUserAsync(new UserRecordArgs { Uid = uid, Disabled = disabled });
        if (disabled) await auth.RevokeRefreshTokensAsync(uid);
        await db.Collection("users").Document(uid).UpdateAsync(new Dictionary<string, object?>
        {
            ["status"] = request.Status,
            ["updatedAt"] = FieldValue.ServerTimestamp,
        });
        return Results.Ok(new { id = uid, status = request.Status });
    }
    catch (Exception exception)
    {
        return FirebaseFailure(exception);
    }
});

app.MapDelete("/api/admin/users/{uid}", async (
    string uid,
    HttpRequest httpRequest,
    FirebaseAuth auth,
    FirestoreDb db) =>
{
    var access = await RequireAdminAsync(httpRequest, auth, db);
    if (access.Error is not null) return access.Error;
    if (uid == access.Token!.Uid) return BadRequest("Không thể tự xóa tài khoản admin đang đăng nhập.");

    try
    {
        await auth.DeleteUserAsync(uid);
        var batch = db.StartBatch();
        batch.Delete(db.Collection("users").Document(uid));
        batch.Delete(db.Collection("userAvatars").Document(uid));
        await batch.CommitAsync();
        return Results.NoContent();
    }
    catch (Exception exception)
    {
        return FirebaseFailure(exception);
    }
});

app.Run();

static async Task<(FirebaseToken? Token, IResult? Error)> RequireAdminAsync(
    HttpRequest request,
    FirebaseAuth auth,
    FirestoreDb db)
{
    var header = request.Headers.Authorization.ToString();
    if (!header.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
        return (null, Results.Json(new { message = "Thiếu Firebase ID token." }, statusCode: 401));

    try
    {
        var token = await auth.VerifyIdTokenAsync(header[7..].Trim(), true);
        var isAdminClaim = token.Claims.TryGetValue("admin", out var claim) && claim is true;
        if (!isAdminClaim)
        {
            var snapshot = await db.Collection("users").Document(token.Uid).GetSnapshotAsync();
            var profile = snapshot.Exists ? snapshot.ToDictionary() : null;
            isAdminClaim = profile?.TryGetValue("role", out var role) == true
                && role?.ToString() == "admin";
        }
        return isAdminClaim
            ? (token, null)
            : (null, Results.Json(new { message = "Tài khoản không có quyền admin." }, statusCode: 403));
    }
    catch
    {
        return (null, Results.Json(new { message = "Phiên đăng nhập không hợp lệ hoặc đã hết hạn." }, statusCode: 401));
    }
}

static string? ValidateUser(string name, string email, string phone, int age)
{
    if (name.Trim().Length < 2) return "Họ tên không hợp lệ.";
    if (!email.Contains('@') || email.Trim().Length < 5) return "Email không hợp lệ.";
    if (phone.Length != 10 || phone.Any(character => !char.IsDigit(character)))
        return "Số điện thoại phải có 10 chữ số.";
    return age is < 1 or > 120 ? "Tuổi phải từ 1 đến 120." : null;
}

static (byte[]? Bytes, string? Error) DecodeAvatar(string? value)
{
    if (string.IsNullOrWhiteSpace(value)) return (null, null);
    try
    {
        var bytes = Convert.FromBase64String(value);
        return bytes.Length <= MaxAvatarBytes
            ? (bytes, null)
            : (null, "Ảnh đại diện vượt quá 700 KB.");
    }
    catch (FormatException)
    {
        return (null, "Dữ liệu ảnh đại diện không hợp lệ.");
    }
}

static Dictionary<string, object?> AvatarData(byte[] bytes, string? contentType) => new()
{
    ["bytes"] = bytes,
    ["contentType"] = string.IsNullOrWhiteSpace(contentType) ? "image/jpeg" : contentType,
    ["updatedAt"] = FieldValue.ServerTimestamp,
};

static IResult BadRequest(string message) =>
    Results.Json(new { message }, statusCode: 400);

static IResult FirebaseFailure(Exception exception)
{
    Console.Error.WriteLine(exception);
    var text = exception.Message.ToLowerInvariant();
    var message = text.Contains("email") && (text.Contains("exist") || text.Contains("use"))
        ? "Email này đã được sử dụng."
        : text.Contains("user") && text.Contains("not found")
            ? "Không tìm thấy tài khoản trong Firebase Authentication."
            : "Firebase không thể hoàn tất thao tác. Kiểm tra log backend.";
    return Results.Json(new { message }, statusCode: 400);
}

internal sealed record CreateUserRequest(
    string Name,
    string Email,
    string Phone,
    int Age,
    string? AvatarBase64,
    string? AvatarContentType);

internal sealed record UpdateUserRequest(
    string Name,
    string Email,
    string Phone,
    int Age,
    string? AvatarBase64,
    string? AvatarContentType,
    bool RemoveAvatar);

internal sealed record StatusRequest(string Status);
