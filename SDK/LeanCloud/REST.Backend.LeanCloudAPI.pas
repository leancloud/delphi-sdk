{*******************************************************}
{                                                       }
{             Delphi REST Client Framework              }
{                                                       }
{ Copyright(c) 2015 yuanpeng                            }
{                                                       }
{*******************************************************}
unit REST.Backend.LeanCloudApi;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections, System.JSON,
  REST.Client, REST.Types, REST.Backend.Exception;

resourcestring
  sFormatLeanCloudError = 'LeanCloud Error: %0:s (%1:d)';

{$SCOPEDENUMS ON}

type

  ELeanCloudAPIError = class(EBackendError)
  private
    FCode: Integer;
    FError: string;
  public
    constructor Create(ACode: Integer; const AError: String); overload;
    property Code: Integer read FCode;
    property Error: string read FError;
  end;

  TLeanCloudAPIErrorClass = class of ELeanCloudAPIError;

  /// <summary>
  /// <para>
  /// TLeanCloudApi implements REST requests based on LeanCloud's REST API. See
  /// <see href="https://leancloud.cn/docs/rest_api.html" />
  /// </para>
  /// </summary>
  TLeanCloudApi = class(TComponent)
  private const
    sClasses = 'classes';
    sInstallations = 'installations';
    sFiles = 'files';
    sUsers = 'users';
    sPush = 'push';
  public const
    cDefaultApiVersion = '1.1';
    cDefaultBaseURL = 'https://leancloud.cn/{ApiVersion}'; // do not localize
  public type

    TDeviceNames = record
    public
      const IOS = 'ios';
      const Android = 'android';
    end;

    TConnectionInfo = record
    public
      ApiVersion: string;
      ApplicationID: string;
      RestApiKey: string;
      MasterKey: string;
      ProxyPassword: string;
      ProxyPort: Integer;
      ProxyServer: string;
      ProxyUsername: string;
      constructor Create(const AApiVersion, AApplicationID: string);
    end;

//    TIncrement = TPair<string, Integer>;
//    TIncrements = TArray<TIncrement>;

    TUpdatedAt = record
    private
      FUpdatedAt: TDateTime;
      FObjectID: string;
      FBackendClassName: string;
    public
      constructor Create(const ABackendClassName, AObjectID: string; AUpdatedAt: TDateTime);
      property UpdatedAt: TDateTime read FUpdatedAt;
      property ObjectID: string read FObjectID;
      property BackendClassName: string read FBackendClassName;
    end;

                            

    TObjectID = record
    private
      FCreatedAt: TDateTime;
      FUpdatedAt: TDateTime;
      FObjectID: string;
      FBackendClassName: string;
    public
      constructor Create(const ABackendClassName: string; AObjectID: string);
      property CreatedAt: TDateTime read FCreatedAt;
      property UpdatedAt: TDateTime read FUpdatedAt;
      property ObjectID: string read FObjectID;
      property BackendClassName: string read FBackendClassName;
    end;

    TUser = record
    private
      FCreatedAt: TDateTime;
      FUpdatedAt: TDateTime;
      FObjectID: string;
      FUserName: string;
    public
      constructor Create(const AUserName: string);
      property CreatedAt: TDateTime read FCreatedAt;
      property UpdatedAt: TDateTime read FUpdatedAt;
      property ObjectID: string read FObjectID;
      property UserName: string read FUserName;
    end;

    TLogin = record
    private
      FSessionToken: string;
      FUser: TUser;
    public
      constructor Create(const ASessionToken: string; const AUser: TUser);
      property SessionToken: string read FSessionToken;
      property User: TUser read FUser;
    end;

    TFile = record
    private
      FName: string;
      FFileName: string;
      FDownloadURL: string;
    public
      constructor Create(const AName: string);
      property FileName: string read FFileName;
      property DownloadURL: string read FDownloadURL;
      property Name: string read FName;
    end;

    TAuthentication = (Default, MasterKey, APIKey, Session, None);
    TAuthentications = set of TAuthentication;
    TDefaultAuthentication = (APIKey, MasterKey, Session, None);

    TFindObjectProc = reference to procedure(const AID: TObjectID; const AObj: TJSONObject);
    TQueryUserNameProc = reference to procedure(const AUser: TUser; const AUserObject: TJSONObject);
    TLoginProc = reference to procedure(const ALogin: TLogin; const AUserObject: TJSONObject);
    TRetrieveUserProc = reference to procedure(const AUser: TUser; const AUserObject: TJSONObject);

  public
    const
      DateTimeIsUTC = True;
  public
    class var
      EmptyConnectionInfo: TConnectionInfo;
  private
    FRESTClient: TRESTClient;
    FRequest: TRESTRequest;
    FResponse: TRESTResponse;
    FOwnsResponse: Boolean;
    FBaseURL: string;
    FConnectionInfo: TConnectionInfo;
    FSessionToken: string;
    FAuthentication: TAuthentication;
    FDefaultAuthentication: TDefaultAuthentication;
    procedure SetConnectionInfo(const Value: TConnectioninfo);
    procedure SetBaseURL(const Value: string);
    function GetLoggedIn: Boolean;
  protected
    procedure AddMasterKey(const AKey: string); overload;
    procedure AddAPIKey(const AKey: string); overload;
    procedure AddSessionToken(const AAPIKey, ASessionToken: string); overload;
    procedure ApplyConnectionInfo;
    procedure CheckAuthentication(AAuthentication: TAuthentications);
    function GetActualAuthentication: TAuthentication;
    function CreateException(const ARequest: TRESTRequest;
      const AClass: TLeanCloudAPIErrorClass): ELeanCloudAPIError;
    procedure CheckForResponseError(AValidStatusCodes: array of Integer); overload;
    procedure CheckForResponseError; overload;
    procedure CheckForResponseError(const ARequest: TRESTRequest); overload;
    procedure CheckForResponseError(const ARequest: TRESTRequest;
      AValidStatusCodes: array of Integer); overload;
    procedure PostResource(const AResource: string;
      const AJSON: TJSONObject; AReset: Boolean);
    procedure PutResource(const AResource: string;
      const AJSONObject: TJSONObject; AReset: Boolean);
    function DeleteResource(const AResource: string; AReset: Boolean): Boolean; overload;
    function ObjectIDFromObject(const ABackendClassName, AObjectID: string;
      const AJSONObject: TJSONObject): TObjectID; overload;
    function FileIDFromObject(const AFileName: string; const AJSONObject: TJSONObject): TFile;
    procedure AddAuthParameters; overload;
    procedure AddAuthParameters(AAuthentication: TAuthentication); overload;
    function FindClass(const ABackendClassName, AObjectID: string; out AFoundObject: TObjectID; const AJSON: TJSONArray; AProc: TFindObjectProc): Boolean; overload;
    function QueryUserName(const AUserName: string; out AUser: TUser; const AJSON: TJSONArray; AProc: TQueryUserNameProc): Boolean; overload;
    function LoginFromObject(const AUserName: string; const AJSONObject: TJSONObject): TLogin;
    function UserFromObject(const AUserName: string; const AJSONObject: TJSONObject): TUser; overload;
    function UpdatedAtFromObject(const ABackendClassName, AObjectID: string; const AJSONObject: TJSONObject): TUpdatedAt;
    procedure QueryResource(const AResource: string; const AQuery: array of string; const AJSONArray: TJSONArray; AReset: Boolean);
    function RetrieveCurrentUser(const ASessionToken: string; out AUser: TUser; const AJSON: TJSONArray; AProc: TRetrieveUserProc): Boolean; overload;
    function RetrieveUser(const ASessionID, AObjectID: string; out AUser: TUser; const AJSON: TJSONArray; AProc: TRetrieveUserProc; AReset: Boolean): Boolean; overload;
    procedure UpdateUser(const ASessionID, AObjectID: string; const AUserObject: TJSONObject; out AUpdatedAt: TUpdatedAt); overload;
    property RestClient: TRESTClient read FRESTClient;
    property Request: TRESTRequest read FRequest;
  public
    constructor Create(AOwner: TComponent;
      const AResponse: TRESTResponse = nil); reintroduce; overload;
    destructor Destroy; override;
    function UserFromObject(const AJSONObject: TJSONObject): TUser; overload;
    function ObjectIDFromObject(const ABackendClassName: string;
      const AJSONObject: TJSONObject): TObjectID; overload;
    // Objects
    procedure CreateClass(const ABackendClassName: string; const AJSON: TJSONObject; out ANewObject: TObjectID); overload;
    procedure CreateClass(const ABackendClassName: string; const AACL, AJSON: TJSONObject; out ANewObject: TObjectID); overload;
                                                   
    function DeleteClass(const AID: TObjectID): Boolean; overload;
    function DeleteClass(const ABackendClassName, AObjectID: string): Boolean; overload;
    function FindClass(const ABackendClassName, AObjectID: string; AProc: TFindObjectProc): Boolean; overload;
    function FindClass(const ABackendClassName, AObjectID: string; out AFoundObjectID: TObjectID; const AFoundJSON: TJSONArray = nil): Boolean; overload;
    function FindClass(const AID: TObjectID; AProc: TFindObjectProc): Boolean; overload;
    function FindClass(const AID: TObjectID; out AFoundObjectID: TObjectID; const AFoundJSON: TJSONArray = nil): Boolean; overload;
    procedure UpdateClass(const ABackendClassName, AObjectID: string; const AJSONObject: TJSONObject; out AUpdatedAt: TUpdatedAt); overload;
    procedure UpdateClass(const AID: TObjectID; const AJSONObject: TJSONObject; out AUpdatedAt: TUpdatedAt); overload;
    procedure QueryClass(const ABackendClassName: string; const AQuery: array of string; const AJSONArray: TJSONArray); overload;
    procedure QueryClass(const ABackendClassName: string; const AQuery: array of string; const AJSONArray: TJSONArray; out AObjects: TArray<TObjectID>); overload;
    // Installations
    function CreateAndroidInstallationObject(const AInstallationID, ADeviceToken: string; AChannels: array of string): TJSONObject;
    function CreateIOSInstallationObject(const ADeviceToken: string; ABadge: Integer; AChannels: array of string): TJSONObject;
    procedure UploadInstallation(const AJSON: TJSONObject; out ANewObject: TObjectID);
    procedure UpdateInstallation(const AObjectID: string; const AJSONObject: TJSONObject; out AUpdatedAt: TUpdatedAt);
    function DeleteInstallation(const AObjectID: string): Boolean; overload;
    procedure QueryInstallation(const AQuery: array of string; const AJSONArray: TJSONArray); overload;
    procedure QueryInstallation(const AQuery: array of string; const AJSONArray: TJSONArray; out AObjects: TArray<TObjectID>); overload;
    // Push
    procedure PushBody(const AMessage: TJSONObject);
    procedure PushToDevices(const ADevices: array of string; const AData: TJSONObject);
    procedure PushBroadcast(const AData: TJSONObject);
    procedure PushToChannels(const AChannels: array of string; const AData: TJSONObject);
    procedure PushWhere(const AWhere: TJSONObject; const AData: TJSONObject);
    // Files
    procedure UploadFile(const AFileName: string; const AContentType: string; out ANewFile: TFile); overload;
    procedure UploadFile(const AFileName: string; const AStream: TStream; const AContentType: string; out ANewFile: TFile); overload;
    function DeleteFile(const AFileID: TFile): Boolean;
    // Users
    function QueryUserName(const AUserName: string; AProc: TQueryUserNameProc): Boolean; overload;
    function QueryUserName(const AUserName: string; out AUser: TUser; const AJSON: TJSONArray = nil): Boolean; overload;
    function RetrieveUser(const AObjectID: string; AProc: TRetrieveUserProc): Boolean; overload;
    function RetrieveUser(const AObjectID: string; out AUser: TUser; const AJSON: TJSONArray = nil): Boolean; overload;
    function RetrieveUser(const ALogin: TLogin; AProc: TRetrieveUserProc): Boolean; overload;
    function RetrieveUser(const ALogin: TLogin; out AUser: TUser; const AJSON: TJSONArray): Boolean; overload;
    procedure SignupUser(const AUserName, APassword: string; const AUserFields: TJSONObject; out ANewUser: TLogin);
    procedure LoginUser(const AUserName, APassword: string; AProc: TLoginProc); overload;
    procedure LoginUser(const AUserName, APassword: string; out ALogin: TLogin; const AJSONArray: TJSONArray = nil); overload;
    function RetrieveCurrentUser(AProc: TRetrieveUserProc): Boolean; overload;
    function RetrieveCurrentUser(out AUser: TUser; const AJSON: TJSONArray = nil): Boolean; overload;
    function RetrieveCurrentUser(const ALogin: TLogin; AProc: TRetrieveUserProc): Boolean; overload;
    function RetrieveCurrentUser(const ALogin: TLogin; const AJSON: TJSONArray): Boolean; overload;
    procedure UpdateUser(const AObjectID: string; const AUserObject: TJSONObject; out AUpdatedAt: TUpdatedAt); overload;
    procedure UpdateUser(const ALogin: TLogin; const AUserObject: TJSONObject; out AUpdatedAt: TUpdatedAt); overload;
    function DeleteUser(const AObjectID: string): Boolean; overload;
    function DeleteUser(const ALogin: TLogin): Boolean; overload;
    procedure QueryUsers(const AQuery: array of string; const AJSONArray: TJSONArray); overload;
    procedure QueryUsers(const AQuery: array of string; const AJSONArray: TJSONArray; out AUsers: TArray<TUser>); overload;
    procedure Login(const ASessionToken: string); overload;
    procedure Login(const ALogin: TLogin); overload;
    procedure Logout;
    property LoggedIn: Boolean read GetLoggedIn;
    property Authentication: TAuthentication read FAuthentication write FAuthentication;
    property DefaultAuthentication: TDefaultAuthentication read FDefaultAuthentication write FDefaultAuthentication;
    property Response: TRESTResponse read FResponse;
    property BaseURL: string read FBaseURL write SetBaseURL;
    property ConnectionInfo: TConnectioninfo read FConnectionInfo write SetConnectionInfo;
  end;

implementation

uses System.DateUtils, System.Rtti, REST.Exception, REST.JSON.Types, System.TypInfo,
  REST.Backend.Consts;

procedure CheckObjectID(const AObjectID: string);
begin
  if AObjectID = '' then
    raise ELeanCloudAPIError.Create(sObjectIDRequired);
end;

procedure CheckMasterKey(const AMasterKey: string);
begin
  if AMasterKey = '' then
    raise ELeanCloudAPIError.Create(sMasterKeyRequired);
end;

procedure CheckSessionID(const SessionID: string);
begin
  if SessionID = '' then
    raise ELeanCloudAPIError.Create(sSessionIDRequired);
end;

procedure CheckAPIKey(const AKey: string);
begin
  if AKey = '' then
    raise ELeanCloudAPIError.Create(sAPIKeyRequired);
end;

procedure CheckBackendClass(const ABackendClassName: string);
begin
  if ABackendClassName = '' then
    raise ELeanCloudAPIError.Create(sBackendClassNameRequired);
end;

procedure CheckJSONObject(const AJSON: TJSONObject);
begin
  if AJSON = nil then
    raise ELeanCloudAPIError.Create(sJSONObjectRequired);
end;

constructor TLeanCloudApi.Create(AOwner: TComponent;
  const AResponse: TRESTResponse);
begin
  inherited Create(AOwner);
  FConnectionInfo := TConnectionInfo.Create(cDefaultApiVersion, '');
  FRESTClient := TRESTClient.Create(nil);
  FRESTClient.SynchronizedEvents := False;
  FRequest := TRESTRequest.Create(nil);
  FRequest.SynchronizedEvents := False;
  FRequest.Client := FRESTClient;
  FOwnsResponse := AResponse = nil;
  if FOwnsResponse then
    FResponse := TRESTResponse.Create(nil)
  else
    FResponse := AResponse;
  FRequest.Response := FResponse;
  BaseURL := cDefaultBaseURL;
  ApplyConnectionInfo;
end;

// LeanCloud installation json
//deviceType "ios" or "android"
//installationId android
//deviceToken ios
//badge ios
//timeZone both
//channels  both

function TLeanCloudApi.CreateIOSInstallationObject(const ADeviceToken: string; ABadge: Integer;
  AChannels: array of string): TJSONObject;
var
  LArray: TJSONArray;
  S: string;
begin
  Result := TJSONObject.Create;
  Result.AddPair('deviceType', TJSONString.Create(TDeviceNames.IOS)); // Do not localize
  Result.AddPair('deviceToken', TJSONString.Create(ADeviceToken));    // Do not localize
  Result.AddPair('badge', TJSONNumber.Create(ABadge));                // Do not localize
  LArray := TJSONArray.Create;
  for S in AChannels do
    LArray.AddElement(TJSONString.Create(S));
                   
  // Result.AddPair('timeZone', TJSONString.Create(????));
  Result.AddPair('channels', LArray);   // empty channels              // Do not localize
end;

function TLeanCloudApi.CreateAndroidInstallationObject(const AInstallationID, ADeviceToken: string; AChannels: array of string): TJSONObject;
var
  LArray: TJSONArray;
  S: string;
begin
  Result := TJSONObject.Create;
  Result.AddPair('deviceType', TJSONString.Create(TDeviceNames.Android));   // Do not localize
  Result.AddPair('pushType', 'gcm');                                     // Do not localize
  Result.AddPair('deviceToken', TJSONString.Create(ADeviceToken));       // Do not localize
  Result.AddPair('installationId', TJSONString.Create(AInstallationID));       // Do not localize
  LArray := TJSONArray.Create;
  for S in AChannels do
    LArray.AddElement(TJSONString.Create(S));
                   
  // Result.AddPair('timeZone', TJSONString.Create(????));
  Result.AddPair('channels', LArray);   // empty channels                      // Do not localize
end;

const
  sApiVersion = 'ApiVersion';
  sApplicationId = 'X-AVOSCloud-Application-Id';
  sRESTAPIKey = 'X-AVOSCloud-Application-Key';
  sMasterKey = 'X-AVOSCloud-Master-Key';
  sSessionToken = 'X-AVOSCloud-Session-Token';

procedure TLeanCloudApi.ApplyConnectionInfo;
begin
  FRESTClient.Params.AddUrlSegment(sApiVersion, FConnectionInfo.ApiVersion);
  FRESTClient.Params.AddHeader(sApplicationId, FConnectionInfo.ApplicationID);
  FRESTClient.ProxyPort := FConnectionInfo.ProxyPort;
  FRESTClient.ProxyPassword := FConnectionInfo.ProxyPassword;
  FRESTClient.ProxyUsername := FConnectionInfo.ProxyUsername;
  FRESTClient.ProxyServer := FConnectionInfo.ProxyServer;
end;

procedure TLeanCloudApi.AddMasterKey(const AKey: string);
begin
  CheckMasterKey(AKey);
  FRequest.Params.AddHeader(sMasterKey, AKey);
end;

procedure TLeanCloudApi.AddSessionToken(const AAPIKey, ASessionToken: string);
begin
  CheckSessionID(ASessionToken);
  FRequest.Params.AddHeader(sSessionToken, ASessionToken);
  AddAPIKey(AAPIKey); // Need REST API Key with session token
end;

procedure TLeanCloudApi.AddAPIKey(const AKey: string);
begin
  CheckAPIKey(AKey);
  FRequest.Params.AddHeader(sRESTAPIKey, AKey);
end;

procedure TLeanCloudAPI.CheckAuthentication(AAuthentication: TAuthentications);
var
  LAuthentication: TAuthentication;
  LInvalid: string;
  LValid: string;
  LValidItems: TStrings;
begin
  LAuthentication := GetActualAuthentication;
  if not (LAuthentication in AAuthentication) then
  begin
    LInvalid :=  System.TypInfo.GetEnumName(TypeInfo(TAuthentication), Integer(LAuthentication));
    LValidItems := TStringList.Create;
    try
      for LAuthentication in AAuthentication do
        LValidItems.Add(System.TypInfo.GetEnumName(TypeInfo(TAuthentication), Integer(LAuthentication)));
      if LValidItems.Count = 1 then
        LValid := Format(sUseValidAuthentication, [LValidItems[0]])
      else
      begin
        LValid := LValidItems[LValidItems.Count - 1];
        LValidItems.Delete(LValidItems.Count-1);
        LValidItems.Delimiter := ',';
        LValid := Format(sUseValidAuthentications, [LValidItems.DelimitedText, LValid])
      end;

    finally
      LValidItems.Free;
    end;

    raise ELeanCloudAPIError.CreateFmt(sInvalidAuthenticationForThisOperation, [LInvalid, LValid]);
  end;
end;

function TLeanCloudAPI.GetActualAuthentication: TAuthentication;
var
  LAuthentication: TAuthentication;
begin
  LAuthentication := FAuthentication;
  if LAuthentication = TAuthentication.Default then
    case FDefaultAuthentication of
      TDefaultAuthentication.MasterKey:
        LAuthentication := TAuthentication.MasterKey;
      TDefaultAuthentication.APIKey:
        LAuthentication := TAuthentication.ApiKey;
      TLeanCloudApi.TDefaultAuthentication.Session:
        LAuthentication := TAuthentication.Session;
      TLeanCloudApi.TDefaultAuthentication.None:
        LAuthentication := TAuthentication.None;
    else
      Assert(False);
    end;
  Result := LAuthentication;
end;

procedure TLeanCloudApi.AddAuthParameters;
var
  LAuthentication: TAuthentication;
begin
  LAuthentication := GetActualAuthentication;
  AddAuthParameters(LAuthentication);
end;

procedure TLeanCloudApi.AddAuthParameters(AAuthentication: TAuthentication);
begin
  case AAuthentication of
    TLeanCloudApi.TAuthentication.APIKey:
      AddAPIKey(ConnectionInfo.RestApiKey);
    TLeanCloudApi.TAuthentication.MasterKey:
      AddMasterKey(ConnectionInfo.MasterKey);
    TLeanCloudApi.TAuthentication.Session:
      AddSessionToken(ConnectionInfo.RESTApiKey, FSessionToken);
    TLeanCloudApi.TAuthentication.None:
      ;
  else
    Assert(False);
  end;
end;

function TLeanCloudApi.CreateException(const ARequest: TRESTRequest;
  const AClass: TLeanCloudAPIErrorClass): ELeanCloudAPIError;
var
  LCode: Integer;
  LMessage: string;
  LJSONCode: TJSONValue;
  LJSONMessage: TJSONValue;
begin
  if ARequest.Response.JSONValue <> nil then
  begin
    LJSONCode := (ARequest.Response.JSONValue as TJSONObject).GetValue('code');     // Do not localize
    if LJSONCode <> nil then
      LCode := StrToInt(LJSONCode.Value)
    else
      LCode := 0;
    LJSONMessage := (ARequest.Response.JSONValue as TJSONObject).GetValue('error');     // Do not localize
    if LJSONMessage <> nil then
      LMessage := LJSONMessage.Value;
    if (LJSONCode <> nil) and (LJSONMessage <> nil) then
      Result :=  TLeanCloudAPIErrorClass.Create(LCode, LMessage)
    else if LJSONMessage <> nil then
      Result := TLeanCloudAPIErrorClass.Create(LMessage)
    else
      Result := TLeanCloudAPIErrorClass.Create(ARequest.Response.Content);
  end
  else
    Result := TLeanCloudAPIErrorClass.Create(ARequest.Response.Content);
end;

procedure TLeanCloudApi.CheckForResponseError;
begin
  CheckForResponseError(FRequest);
end;

procedure TLeanCloudApi.CheckForResponseError(const ARequest: TRESTRequest);
begin
  if ARequest.Response.StatusCode >= 300 then
  begin
    if (ARequest.Response.StatusCode >= 400) and (ARequest.Response.StatusCode < 500)
       and (ARequest.Response.JSONValue <> nil) then
    begin
      raise CreateException(ARequest, ELeanCloudAPIError);
    end
    else
      raise ELeanCloudAPIError.Create(ARequest.Response.Content);
  end
end;

procedure TLeanCloudApi.CheckForResponseError(AValidStatusCodes: array of Integer);
begin
  CheckForResponseError(FRequest, AValidStatusCodes);
end;

procedure TLeanCloudApi.CheckForResponseError(const ARequest: TRESTRequest; AValidStatusCodes: array of Integer);
var
  LCode: Integer;
  LResponseCode: Integer;
begin
  LResponseCode := ARequest.Response.StatusCode;

  for LCode in AValidStatusCodes do
    if LResponseCode = LCode then
      Exit; // Code is valid, exit with no exception
  CheckForResponseError(ARequest);
end;

function TLeanCloudApi.DeleteClass(const AID: TObjectID): Boolean;
begin
  Result := DeleteClass(AID.BackendClassName, AID.ObjectID);
end;

function TLeanCloudApi.DeleteResource(const AResource: string; AReset: Boolean): Boolean;
begin
  Assert(AResource <> '');
  if AReset then
  begin
    FRequest.ResetToDefaults;
    AddAuthParameters;
  end;
  FRequest.Method := TRESTRequestMethod.rmDELETE;
  FRequest.Resource := AResource;
  FRequest.Execute;
  CheckForResponseError([404]);
  Result := FRequest.Response.StatusCode <> 404
end;

function TLeanCloudApi.DeleteClass(const ABackendClassName: string; const AObjectID: string): Boolean;
begin
  CheckBackendClass(ABackendClassName);
  CheckObjectID(AObjectID);
  FRequest.ResetToDefaults;
  AddAuthParameters;
  Result := DeleteResource(sClasses + '/' + ABackendClassname + '/' + AObjectID, False);
end;

function TLeanCloudApi.DeleteInstallation(const AObjectID: string): Boolean;
begin
  FRequest.ResetToDefaults;
  AddAuthParameters(TAuthentication.MasterKey); // Required
  Result := DeleteResource(sInstallations + '/' + AObjectID, False);
end;

////curl -X GET \
////  -H "X-AVOSCloud-Application-Id: appidgoeshere" \
////  -H "X-AVOSCloud-Master-Key: masterkeygoeshere" \
////  https://LeanCloud.cn/1/installations
procedure TLeanCloudApi.QueryInstallation(const AQuery: array of string; const AJSONArray: TJSONArray);
begin
  FRequest.ResetToDefaults;
  AddAuthParameters;
  QueryResource(sInstallations, AQuery, AJSONArray, False);
end;

procedure TLeanCloudApi.QueryInstallation(const AQuery: array of string; const AJSONArray: TJSONArray; out AObjects: TArray<TObjectID>);
var
  LJSONValue: TJSONValue;
  LList: TList<TObjectID>;
  LInstallation: TObjectID;
begin
  FRequest.ResetToDefaults;
  AddAuthParameters(TAuthentication.MasterKey);     // Master required
  QueryResource(sInstallations, AQuery, AJSONArray, False);
  LList := TList<TObjectID>.Create;
  try
    for LJSONValue in AJSONArray do
    begin
      if LJSONValue is TJSONObject then
      begin
        // Blank backend class name
        LInstallation := ObjectIDFromObject('', TJSONObject(LJSONValue));
        LList.Add(LInstallation);
      end
      else
        raise ELeanCloudAPIError.Create(sJSONObjectExpected);
    end;
    AObjects := LList.ToArray;
  finally
    LList.Free;
  end;
end;

destructor TLeanCloudApi.Destroy;
begin
  FRESTClient.Free;
  FRequest.Free;
  if FOwnsResponse then
    FResponse.Free;
  inherited;
end;

procedure TLeanCloudApi.QueryResource(const AResource: string; const AQuery: array of string; const AJSONArray: TJSONArray; AReset: Boolean);
var
  LRoot: TJSONArray;
  S: string;
  I: Integer;
  LJSONValue: TJSONValue;
begin
  if AReset then
  begin
    FRequest.ResetToDefaults;
    AddAuthParameters;
  end;
  FRequest.Method := TRESTRequestMethod.rmGET;
  FRequest.Resource := AResource;

  for S in AQuery do
  begin
    I := S.IndexOf('=');
    if I > 0 then
      FRequest.AddParameter(S.Substring(0, I).Trim, S.Substring(I+1).Trim);
  end;
  FRequest.Execute;
  CheckForResponseError([404]); // 404 = not found
  if FRequest.Response.StatusCode <> 404 then
  begin
    // {"results":[{"Age":1,"age":42,"name":"Elmo","createdAt":"2013-11-02T18:09:30.751Z","updatedAt":"2013-11-02T18:11:27.910Z","objectId":"dB9jr8Su8u"},{"age":43,"name":"Elmo","createdAt":"2013-11-02T18:17:48.564Z","updatedAt":"2013-11-02T18:18:03.863Z","objectId":"cT7blzwGxV"},
    LRoot := (FRequest.Response.JSONValue as TJSONObject).GetValue('results') as TJSONArray;   // Do not localize
    for LJSONValue in LRoot do
      AJSONArray.AddElement(TJSONValue(LJSONValue.Clone))
  end;
end;

procedure TLeanCloudApi.QueryClass(const ABackendClassName: string; const AQuery: array of string; const AJSONArray: TJSONArray);
begin
  QueryResource(sClasses + '/' + ABackendClassname, AQuery, AJSONArray, True);
end;

procedure TLeanCloudApi.QueryClass(const ABackendClassName: string; const AQuery: array of string; const AJSONArray: TJSONArray; out AObjects: TArray<TObjectID>);
var
  LJSONValue: TJSONValue;
  LList: TList<TObjectID>;
  LObjectID: TObjectID;
begin
  CheckBackendClass(ABackendClassName);
  FRequest.ResetToDefaults;
  AddAuthParameters;
  QueryResource(sClasses + '/' + ABackendClassname, AQuery, AJSONArray, False);
  LList := TList<TObjectID>.Create;
  try
    for LJSONValue in AJSONArray do
    begin
      if LJSONValue is TJSONObject then
      begin
        LObjectID := ObjectIDFromObject(ABackendClassName, TJSONObject(LJSONValue));
        LList.Add(LObjectID);
      end
      else
        raise ELeanCloudAPIError.Create(sJSONObjectExpected);
    end;
    AObjects := LList.ToArray;
  finally
    LList.Free;
  end;
end;

function ValueToJsonValue(AValue: TValue): TJSONValue;
begin
  if AValue.IsType<Int64> then
    Result := TJSONNumber.Create(AValue.AsInt64)
  else if AValue.IsType<Extended> then
    Result := TJSONNumber.Create(AValue.AsExtended)
  else if AValue.IsType<string> then
    Result := TJSONString.Create(AValue.AsString)
  else
    Result := TJSONString.Create(AValue.ToString)
end;

function TLeanCloudApi.FindClass(const ABackendClassName, AObjectID: string; out AFoundObject: TObjectID; const AJSON: TJSONArray; AProc: TFindObjectProc): Boolean;
var
  LResponse: TJSONObject;
begin
  CheckBackendClass(ABackendClassName);
  CheckObjectID(AObjectID);
  Result := False;
  FRequest.ResetToDefaults;
  AddAuthParameters;
  FRequest.Method := TRESTRequestMethod.rmGET;
  FRequest.Resource := sClasses + '/'  + ABackendClassname + '/' + AObjectID;
  FRequest.Execute;
  CheckForResponseError([404]); // 404 = not found
  if FRequest.Response.StatusCode <> 404 then
  begin
    Result := True;
    // '{"createdAt":"2013-10-16T20:21:57.326Z","objectId":"5328czuo2e"}'
    LResponse := FRequest.Response.JSONValue as TJSONObject;
    AFoundObject := ObjectIDFromObject(ABackendClassName, LResponse);
    if Assigned(AJSON) then
      AJSON.AddElement(LResponse.Clone as TJSONObject);
    if Assigned(AProc) then
    begin
      AProc(AFoundObject, LResponse);
    end;
  end;
end;

function TLeanCloudApi.FindClass(const ABackendClassName, AObjectID: string; AProc: TFindObjectProc): Boolean;
var
  LObjectID: TObjectID;
begin
  Result := FindClass(ABackendClassName, AObjectID, LObjectID, nil, AProc);
end;

function TLeanCloudApi.FindClass(const ABackendClassName, AObjectID: string; out AFoundObjectID: TObjectID; const AFoundJSON: TJSONArray): Boolean;
begin
  Result := FindClass(ABackendClassName, AObjectID, AFoundObjectID, AFoundJSON, nil);
end;

function TLeanCloudApi.FindClass(const AID: TObjectID; out AFoundObjectID: TObjectID; const AFoundJSON: TJSONArray): Boolean;
begin
  Result := FindClass(AID.BackendClassName, AID.ObjectID, AFoundObjectID, AFoundJSON, nil);
end;

function TLeanCloudApi.FindClass(const AID: TObjectID; AProc: TFindObjectProc): Boolean;
var
  LObjectID: TObjectID;
begin
  Result := FindClass(AID.BackendClassName, AID.ObjectID, LObjectID, nil, AProc);
end;

function TLeanCloudApi.GetLoggedIn: Boolean;
begin
  Result := FSessionToken <> '';
end;

procedure TLeanCloudApi.PushBody(const AMessage: TJSONObject);
begin
  FRequest.ResetToDefaults;
  AddAuthParameters;
  FRequest.Method := TRESTRequestMethod.rmPOST;
  FRequest.Resource := sPush;
  FRequest.AddBody(AMessage);
  FRequest.Execute;
  CheckForResponseError;
end;


//curl -X POST \
//  -H "X-AVOSCloud-Application-Id: appidgoeshere" \
//  -H "X-AVOSCloud-Application-Key: restapikeygoeshere" \
//  -H "Content-Type: application/json" \
//  -d '{
//        "where": {
//          "devicetype": "ios,android",
///        },
//        "data": {
//          "alert": "The Giants won against the Mets 2-3."
//        }
//      }' \
//  https://LeanCloud.cn/1/push
procedure TLeanCloudApi.PushBroadcast(const AData: TJSONObject);
begin
  PushToDevices(TArray<string>.Create(TDeviceNames.Android, TDeviceNames.IOS), AData);
end;

//curl -X POST \
//  -H "X-AVOSCloud-Application-Id: appidgoeshere" \
//  -H "X-AVOSCloud-Application-Key: restapikeygoeshere" \
//  -H "Content-Type: application/json" \
//  -d '{
//        "channels": [
//          "Giants",
//          "Mets"
//        ],
//        "data": {
//          "alert": "The Giants won against the Mets 2-3."
//        }
//      }' \
//  https://LeanCloud.cn/1/push
procedure TLeanCloudApi.PushToChannels(const AChannels: array of string; const AData: TJSONObject);
var
  LJSON: TJSONObject;
  LChannels: TJSONArray;
  S: string;
begin
  if Length(AChannels) = 0 then
    raise ELeanCloudAPIError.Create(sChannelNamesExpected);
  LJSON := TJSONObject.Create;
  try
    LChannels := TJSONArray.Create;
    for S in AChannels do
      LChannels.Add(S);
    LJSON.AddPair('channels', LChannels);                    // Do not localize
    LJSON.AddPair('data', AData.Clone as TJSONObject);       // Do not localize
    PushBody(LJSON);
  finally
    LJSON.Free;
  end;
end;

//curl -X POST \
//  -H "X-AVOSCloud-Application-Id: appidgoeshere" \
//  -H "X-AVOSCloud-Application-Key: restapikeygoeshere" \
//  -H "Content-Type: application/json" \
//  -d '{
//        "where": {
//          {"deviceType":{"$in":["ios", "android"]}}
//        },
//        "data": {
//          "alert": "The Giants won against the Mets 2-3."
//        }
//      }' \
//  https://LeanCloud.cn/1/push
procedure TLeanCloudApi.PushWhere(const AWhere: TJSONObject; const AData: TJSONObject);
var
  LJSON: TJSONObject;
begin
  LJSON := TJSONObject.Create;
  try
    if AWhere <> nil then
      LJSON.AddPair('where', AWhere.Clone as TJSONObject);  // Do not localize
    if AData <> nil then
      LJSON.AddPair('data', AData.Clone as TJSONObject);    // Do not localize
    PushBody(LJSON);
  finally
    LJSON.Free;
  end;
end;

//curl -X POST \
//  -H "X-AVOSCloud-Application-Id: appidgoeshere" \
//  -H "X-AVOSCloud-Application-Key: restapikeygoeshere" \
//  -H "Content-Type: application/json" \
//  -d '{
//        "where": {
//          {"deviceType":{"$in":["ios", "android"]}}
//        },
//        "data": {
//          "alert": "The Giants won against the Mets 2-3."
//        }
//      }' \
//  https://LeanCloud.cn/1/push

// where={"score":{"$in":[1,3,5,7,9]}}
procedure TLeanCloudApi.PushToDevices(const ADevices: array of string; const AData: TJSONObject);
var
  LDevices: TJSONArray;
  LWhere: TJSONObject;
  LQuery: TJSONObject;
  S: string;
begin
  if Length(ADevices) = 0 then
    raise ELeanCloudAPIError.Create(sDeviceNamesExpected);
  LDevices := TJSONArray.Create;
  for S in ADevices do
    LDevices.Add(S);
  LQuery := TJSONObject.Create;
  LQuery.AddPair('$in', LDevices);               // Do not localize
  LWhere := TJSONObject.Create;
  try
    LWhere.AddPair('deviceType', LQuery);       // Do not localize
    PushWhere(LWhere, AData);
  finally
    LWhere.Free;
  end;
end;

function TLeanCloudApi.ObjectIDFromObject(const ABackendClassName: string; const AJSONObject: TJSONObject): TObjectID;
var
  LObjectID: string;
begin
  LObjectID := AJSONObject.GetValue('objectId').Value;           // Do not localize
  Result := ObjectIDFromObject(ABackendClassName, LObjectID, AJSONObject);
end;

function TLeanCloudApi.ObjectIDFromObject(const ABackendClassName, AObjectID: string; const AJSONObject: TJSONObject): TObjectID;
begin
  Result := TObjectID.Create(ABackendClassName, AObjectID);
  if AJSONObject.GetValue('createdAt') <> nil then            // Do not localize
    Result.FCreatedAt := TJSONDates.AsDateTime(AJSONObject.GetValue('createdAt'), TJSONDates.TFormat.ISO8601, DateTimeIsUTC);    // Do not localize
  if AJSONObject.GetValue('updatedAt') <> nil then
    Result.FUpdatedAt := TJSONDates.AsDateTime(AJSONObject.GetValue('updatedAt'), TJSONDates.TFormat.ISO8601, DateTimeIsUTC);    // Do not localize
end;

function TLeanCloudApi.FileIDFromObject(const AFileName: string; const AJSONObject: TJSONObject): TFile;
var
  LName: string;
begin
  if AJSONObject.GetValue('name') <> nil then        // Do not localize
    LName := AJSONObject.GetValue('name').Value;      // Do not localize
  Result := TFile.Create(LName);
  Result.FFileName := AFileName;
  if AJSONObject.GetValue('url') <> nil then           // Do not localize
    Result.FDownloadURL := AJSONObject.GetValue('url').Value;      // Do not localize
end;

procedure TLeanCloudApi.Login(const ALogin: TLogin);
begin
  Login(ALogin.SessionToken);
end;

procedure TLeanCloudApi.Login(const ASessionToken: string);
begin
  FSessionToken := ASessionToken;
  FAuthentication := TAuthentication.Session;
end;

function TLeanCloudApi.LoginFromObject(const AUserName: string; const AJSONObject: TJSONObject): TLogin;
var
  LUser: TUser;
  LSessionToken: string;
begin
  LUser := UserFromObject(AUserName, AJSONObject);
  if AJSONObject.GetValue('sessionToken') <> nil then               // Do not localize
    LSessionToken := AJSONObject.GetValue('sessionToken').Value;    // Do not localize
  Assert(LSessionToken <> '');
  Result := TLogin.Create(LSessionToken, LUser);
end;

function TLeanCloudApi.UpdatedAtFromObject(const ABackendClassName, AObjectID: string; const AJSONObject: TJSONObject): TUpdatedAt;
var
  LUpdatedAt: TDateTime;
begin
  if AJSONObject.GetValue('updatedAt') <> nil then                 // Do not localize
    LUpdatedAt := TJSONDates.AsDateTime(AJSONObject.GetValue('updatedAt'), TJSONDates.TFormat.ISO8601, DateTimeIsUTC)  // Do not localize
  else
    LUpdatedAt := 0;
  Result := TUpdatedAt.Create(ABackendClassName, AObjectID, LUpdatedAt);
end;

function TLeanCloudApi.UserFromObject(const AUserName: string; const AJSONObject: TJSONObject): TUser;
begin
  Result := TUser.Create(AUserName);
  if AJSONObject.GetValue('createdAt') <> nil then      // Do not localize
    Result.FCreatedAt := TJSONDates.AsDateTime(AJSONObject.GetValue('createdAt'), TJSONDates.TFormat.ISO8601, DateTimeIsUTC);   // Do not localize
  if AJSONObject.GetValue('updatedAt') <> nil then      // Do not localize
    Result.FUpdatedAt := TJSONDates.AsDateTime(AJSONObject.GetValue('updatedAt'), TJSONDates.TFormat.ISO8601, DateTimeIsUTC);   // Do not localize
  if AJSONObject.GetValue('objectId') <> nil then                                                                               // Do not localize
    Result.FObjectID := AJSONObject.GetValue('objectId').Value;                                                                 // Do not localize
end;

function TLeanCloudApi.UserFromObject(const AJSONObject: TJSONObject): TUser;
var
  LUserName: string;
begin
  if AJSONObject.GetValue('username') <> nil then            // Do not localize
    LUserName := AJSONObject.GetValue('username').Value;     // Do not localize
  Assert(LUserName <> '');
  Result := UserFromObject(LUserName, AJSONObject);
end;

procedure TLeanCloudApi.PostResource(const AResource: string; const AJSON: TJSONObject; AReset: Boolean);
begin
  CheckJSONObject(AJSON);
  // NEW : POST
  if AReset then
  begin
    FRequest.ResetToDefaults;
    AddAuthParameters;
  end;
  FRequest.Method := TRESTRequestMethod.rmPOST;
  FRequest.Resource := AResource;

  FRequest.AddBody(AJSON);
  FRequest.Execute;
  CheckForResponseError;
end;

procedure TLeanCloudApi.CreateClass(const ABackendClassName: string; const AJSON: TJSONObject;
  out ANewObject: TObjectID);
begin
  CreateClass(ABackendClassName, nil, AJSON, ANewObject);
end;

procedure TLeanCloudApi.CreateClass(const ABackendClassName: string; const AACL, AJSON: TJSONObject;
  out ANewObject: TObjectID);
var
  LResponse: TJSONObject;
  LJSON: TJSONObject;
begin
  CheckBackendClass(ABackendClassName);
  LJSON := nil;
  try
    if (AACL <> nil) and (AJSON <> nil) then
    begin
      LJSON := AJSON.Clone as TJSONObject;
      LJSON.AddPair('ACL', AACL.Clone as TJSONObject);           // Do not localize
    end
    else if AACL <> nil then
      LJSON := AACL
    else
      LJSON := AJSON;
    FRequest.ResetToDefaults;
    AddAuthParameters;
    PostResource(sClasses + '/' + ABackendClassName, LJSON, False);
    // '{"createdAt":"2013-10-16T20:21:57.326Z","objectId":"5328czuo2e"}'
    LResponse := FRequest.Response.JSONValue as TJSONObject;
    ANewObject := ObjectIDFromObject(ABackendClassName, LResponse);
  finally
    if (LJSON <> AACL) and (LJSON <> AJSON) then
      LJSON.Free;
  end;
end;

procedure TLeanCloudApi.PutResource(const AResource: string; const AJSONObject: TJSONObject; AReset: Boolean);
begin
  CheckJSONObject(AJSONObject);
  if AReset then
  begin
    FRequest.ResetToDefaults;
    AddAuthParameters;
  end;
  FRequest.Method := TRESTRequestMethod.rmPUT;
  FRequest.Resource := AResource;
  FRequest.AddBody(AJSONObject);
  FRequest.Execute;
  CheckForResponseError;
end;

procedure TLeanCloudApi.UpdateClass(const ABackendClassName, AObjectID: string; const AJSONObject: TJSONObject; out AUpdatedAt: TUpdatedAt);
var
  LResponse: TJSONObject;
begin
  CheckBackendClass(ABackendClassName);
  CheckObjectID(AObjectID);
  FRequest.ResetToDefaults;
  AddAuthParameters;
  PutResource(sClasses + '/'  + ABackendClassname + '/' + AObjectID, AJSONObject, False);
  LResponse := FRequest.Response.JSONValue as TJSONObject;
  // '{"updatedAt":"2013-10-16T20:21:57.326Z"}'
  AUpdatedAt := UpdatedAtFromObject(ABackendClassName, AObjectID, LResponse);
end;

procedure TLeanCloudApi.UpdateClass(const AID: TObjectID; const AJSONObject: TJSONObject; out AUpdatedAt: TUpdatedAt);
begin
  UpdateClass(AID.BackendClassName, AID.ObjectID, AJSONObject, AUpdatedAt);
end;

procedure TLeanCloudApi.SetBaseURL(const Value: string);
begin
  FBaseURL := Value;
  FRESTClient.BaseURL := Value;
end;

procedure TLeanCloudApi.SetConnectionInfo(const Value: TConnectioninfo);
begin
  FConnectionInfo := Value;
  ApplyConnectionInfo;
end;

procedure TLeanCloudApi.UploadFile(const AFileName: string; const AContentType: string;  out ANewFile: TFile);
var
  LStream: TFileStream;
begin
  LStream := TFileStream.Create(AFileName, 0);
  try
    UploadFile(AFileName, LStream, AContentType, ANewFile);
  finally
    LStream.Free;
  end;
end;

//curl -X POST \
//  -H "X-AVOSCloud-Application-Id: appidgoeshere" \
//  -H "X-AVOSCloud-Application-Key: restapikeygoeshere" \
//  -H "Content-Type: text/plain" \
//  -d 'Hello, World!' \
//  https://LeanCloud.cn/1/files/hello.txt
procedure TLeanCloudApi.UploadFile(const AFileName: string; const AStream: TStream; const AContentType: string; out ANewFile: TFile);
var
  LResponse: TJSONObject;
  LContentType: TRESTContentType;
begin
  FRequest.ResetToDefaults;
  AddAuthParameters;
  FRequest.Method := TRESTRequestMethod.rmPOST;
  FRequest.Resource  := sFiles + '/' + AFileName;
  if AContentType = '' then
    LContentType := TRESTContentType.ctAPPLICATION_OCTET_STREAM
  else
    LContentType :=  ContentTypeFromString(AContentType);
  FRequest.AddBody(AStream, LContentType);
  FRequest.Execute;
  LResponse := FRequest.Response.JSONValue as TJSONObject;
  ANewFile := FileIDFromObject(AFileName, LResponse);
end;

//curl -X DELETE \
//  -H "X-AVOSCloud-Application-Id: appidgoeshere" \
//  -H "X-AVOSCloud-Master-Key: masterkeygoeshere" \
//  https://LeanCloud.cn/1/files/...profile.png
function TLeanCloudApi.DeleteFile(const AFileID: TFile): Boolean;
begin
  FRequest.ResetToDefaults;
  AddAuthParameters(TAuthentication.MasterKey);  //Required
  Result := DeleteResource(sFiles + '/' + AFileID.Name, False);
end;

//curl -X POST \
//  -H "X-AVOSCloud-Application-Id: appidgoeshere" \
//  -H "X-AVOSCloud-Application-Key: restapikeygoeshere" \
//  -H "Content-Type: application/json" \
//  -d '{
//        "deviceType": "ios",
//        "deviceToken": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
//        "channels": [
//          ""
//        ]
//      }' \
//  https://LeanCloud.cn/1/installations
procedure TLeanCloudApi.UploadInstallation(const AJSON: TJSONObject; out ANewObject: TObjectID);
var
  LResponse: TJSONObject;
begin
  PostResource(sInstallations, AJSON, True);
  // '{"createdAt":"2013-10-16T20:21:57.326Z","objectId":"5328czuo2e"}'
  LResponse := FRequest.Response.JSONValue as TJSONObject;
  ANewObject := ObjectIDFromObject('', LResponse);
end;

//curl -X PUT \
//  -H "X-AVOSCloud-Application-Id: appidgoeshere" \
//  -H "X-AVOSCloud-Application-Key: restapikeygoeshere" \
//  -H "Content-Type: application/json" \
//  -d '{
//        "deviceType": "ios",
//        "deviceToken": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
//        "channels": [
//          "",
//          "foo"
//        ]
//      }' \
//  https://LeanCloud.cn/1/installations/mrmBZvsErB
procedure TLeanCloudApi.UpdateInstallation(const AObjectID: string; const AJSONObject: TJSONObject; out AUpdatedAt: TUpdatedAt);
var
  LResponse: TJSONObject;
begin
  CheckObjectID(AObjectID);
  PutResource(sInstallations + '/' + AObjectID, AJSONObject, True);
  LResponse := FRequest.Response.JSONValue as TJSONObject;
  // '{"updatedAt":"2013-10-16T20:21:57.326Z"}'
  AUpdatedAt := UpdatedAtFromObject('', AObjectID, LResponse);
end;


//curl -X DELETE \
//  -H "X-AVOSCloud-Application-Id: appidgoeshere" \
//  -H "X-AVOSCloud-Application-Key: restapikeygoeshere" \
//  -H "X-AVOSCloud-Session-Token: sessiontokengoeshere" \
//  https://LeanCloud.cn/1/users/g7y9tkhB7Oprocedure TLeanCloudApi.UserDelete(const AUser: IBackendUser);
//curl -X DELETE \
//  -H "X-AVOSCloud-Application-Id: appidgoeshere" \
//  -H "X-AVOSCloud-Application-Key: masterkeygoeshere" \
//  https://LeanCloud.cn/1/users/g7y9tkhB7Oprocedure TLeanCloudApi.UserDelete(const AUser: IBackendUser);
function TLeanCloudApi.DeleteUser(const AObjectID: string): Boolean;
begin
  CheckObjectID(AObjectID);
  FRequest.ResetToDefaults;
  // This operation require masterkey or session authentication
  CheckAuthentication([TAuthentication.MasterKey, TAuthentication.Session]);
  AddAuthParameters;
  Result := DeleteResource(sUsers + '/' + AObjectID, False);
end;

function TLeanCloudApi.DeleteUser(const ALogin: TLogin): Boolean;
begin
  CheckObjectID(ALogin.User.ObjectID);
  FRequest.ResetToDefaults;
  AddSessionToken(ConnectionInfo.RestApiKey, ALogin.SessionToken);
  // This operation require masterkey or session authentication
  Result := DeleteResource(sUsers + '/' + ALogin.User.ObjectID, False);
end;

//curl -X GET \
//  -H "X-AVOSCloud-Application-Id: appidgoeshere" \
//  -H "X-AVOSCloud-Application-Key: restapikeygoeshere" \
//  https://LeanCloud.cn/1/users/g1234567
function TLeanCloudAPI.RetrieveUser(const ASessionID, AObjectID: string; out AUser: TUser; const AJSON: TJSONArray;  AProc: TRetrieveUserProc; AReset: Boolean): Boolean;
var
  LResponse: TJSONObject;
begin
  Result := False;
  CheckObjectID(AObjectID);
  if AReset then
  begin
    FRequest.ResetToDefaults;
    if ASessionID <> '' then
      AddSessionToken(ConnectionInfo.RestApiKey, ASessionID)
    else
      AddAuthParameters;
  end;
  FRequest.Method := TRESTRequestMethod.rmGET;
  FRequest.Resource := sUsers + '/'  +  AObjectID;
  FRequest.Execute;
  CheckForResponseError([404]); // 404 = not found
  if FRequest.Response.StatusCode <> 404 then
  begin
    Result := True;
    // '{"createdAt":"2013-10-16T20:21:57.326Z","objectId":"5328czuo2e"}'
    LResponse := FRequest.Response.JSONValue as TJSONObject;
    AUser := UserFromObject(LResponse);
    if AJSON <> nil then
      AJSON.AddElement(LResponse.Clone as TJSONObject);
    if Assigned(AProc) then
      AProc(AUser, LResponse);
  end
end;

function TLeanCloudAPI.RetrieveUser(const AObjectID: string; AProc: TRetrieveUserProc): Boolean;
var
  LUser: TUser;
begin
  Result := RetrieveUser('', AObjectID, LUser, nil, AProc, True);
end;

function TLeanCloudAPI.RetrieveUser(const ALogin: TLogin; AProc: TRetrieveUserProc): Boolean;
var
  LUser: TUser;
begin
  Result := RetrieveUser(ALogin.SessionToken, ALogin.User.ObjectID, LUser, nil, AProc, True);
end;

function TLeanCloudAPI.RetrieveUser(const ALogin: TLogin;  out AUser: TUser; const AJSON: TJSONArray): Boolean;
begin
  Result := RetrieveUser(ALogin.SessionToken, ALogin.User.ObjectID, AUser, AJSON, nil, True);
end;

function TLeanCloudAPI.RetrieveUser(const AObjectID: string; out AUser: TUser; const AJSON: TJSONArray): Boolean;
begin
  Result := RetrieveUser('', AObjectID, AUser, AJSON, nil, True);
end;


//curl -X GET \
//  -H "X-AVOSCloud-Application-Id: appidgoeshere" \
//  -H "X-AVOSCloud-Application-Key: restapikeygoeshere" \
//  -H "X-AVOSCloud-Session-Token: sessiontokengoeshere" \
//  https://LeanCloud.cn/1/users/me
function TLeanCloudAPI.RetrieveCurrentUser(const ASessionToken: string; out AUser: TUser; const AJSON: TJSONArray; AProc: TRetrieveUserProc): Boolean;
begin
  Result := RetrieveUser(ASessionToken, 'me', AUser, AJSON, AProc, True);    // Do not localize
end;

function TLeanCloudAPI.RetrieveCurrentUser(AProc: TRetrieveUserProc): Boolean;
var
  LUser: TUser;
begin
  Result := RetrieveCurrentUser('', LUser, nil, AProc);
end;

function TLeanCloudAPI.RetrieveCurrentUser(const ALogin: TLogin; AProc: TRetrieveUserProc): Boolean;
var
  LUser: TUser;
begin
  Result := RetrieveCurrentUser(ALogin.SessionToken, LUser, nil, AProc);
end;

function TLeanCloudAPI.RetrieveCurrentUser(const ALogin: TLogin; const AJSON: TJSONArray): Boolean;
var
  LUser: TUser;
begin
  Result := RetrieveCurrentUser(ALogin.SessionToken, LUser, AJSON, nil);
end;

function TLeanCloudAPI.RetrieveCurrentUser(out AUser: TUser; const AJSON: TJSONArray): Boolean;
begin
  Result := RetrieveCurrentUser('', AUser, AJSON, nil);
end;

function TLeanCloudApi.QueryUserName(const AUserName: string; out AUser: TUser; const AJSON: TJSONArray; AProc: TQueryUserNameProc): Boolean;
var
  LUsers: TJSONArray;
  LUser: TJSONObject;
begin
  Result := False;
  FRequest.ResetToDefaults;
  AddAuthParameters;
  FRequest.Method := TRESTRequestMethod.rmGET;
  FRequest.Resource := sUsers;

  FRequest.AddParameter('where', TJsonObject.Create.AddPair('username', AUserName)); // do not localize

  FRequest.Execute;
  CheckForResponseError;
  FRequest.Response.RootElement := 'results'; // do not localize
  try
    LUsers := FRequest.Response.JSONValue as TJSONArray;
    if LUsers.Count > 1 then
      raise ELeanCloudAPIError.Create(sOneUserExpected);
    Result := LUsers.Count = 1;
    if Result then
    begin
      LUser := LUsers.Items[0] as TJSONObject;
      AUser := UserFromObject(LUser);
      if Assigned(AJSON) then
        AJSON.AddElement(LUser.Clone as TJSONObject);
      if Assigned(AProc) then
        AProc(AUser, LUser);
    end;
  finally
    FRequest.Response.RootElement := '';
  end;
end;

function TLeanCloudApi.QueryUserName(const AUserName: string; AProc: TQueryUserNameProc): Boolean;
var
  LUser: TUser;
begin
  Result := QueryUserName(AUserName, LUser, nil, AProc);
end;

function TLeanCloudApi.QueryUserName(const AUserName: string; out AUser: TUser; const AJSON: TJSONArray = nil): Boolean;
begin
  Result := QueryUserName(AUserName, AUser, AJSON, nil);
end;


//curl -X GET \
//  -H "X-AVOSCloud-Application-Id: appidgoeshere" \
//  -H "X-AVOSCloud-Application-Key: restapikeygoeshere" \
//  -G \
//  --data-urlencode 'username=passwordgoeshere' \
//  --data-urlencode 'password=passwordgoeshere' \
//  https://LeanCloud.cn/1/login
procedure TLeanCloudApi.LoginUser(const AUserName, APassword: string; AProc: TLoginProc);
var
  LResponse: TJsonObject;
  LLogin: TLogin;
begin
  FRequest.ResetToDefaults;
  AddAuthParameters;
  FRequest.Method := TRESTRequestMethod.rmGET;
  FRequest.Resource := 'login'; // do not localize
  FRequest.Params.AddItem('username', AUserName, TRESTRequestParameterKind.pkGETorPOST); // do not localize
  FRequest.Params.AddItem('password', APassword, TRESTRequestParameterKind.pkGETorPOST); // do not localize

  FRequest.Execute;
  CheckForResponseError;
  LResponse := FRequest.Response.JSONValue as TJSONObject;
  if Assigned(AProc) then
  begin
    LLogin := LoginFromObject(AUserName, LResponse);
    AProc(LLogin, LResponse);
  end;
end;

procedure TLeanCloudApi.Logout;
begin
  FSessionToken := '';
  if FAuthentication = TAuthentication.Session then
    FAuthentication := TAuthentication.Default;
end;

procedure TLeanCloudApi.LoginUser(const AUserName, APassword: string; out ALogin: TLogin; const AJSONArray: TJSONArray);
var
  LLogin: TLogin;
begin
  LoginUser(AUserName, APassword,
    procedure(const ALocalLogin: TLogin; const AUserObject: TJSONObject)
    begin
      LLogin := ALocalLogin;
      if Assigned(AJSONArray) then
        AJSONArray.Add(AUserObject);
    end);
  ALogin := LLogin;
end;

//curl -X POST \
//  -H "X-AVOSCloud-Application-Id: appidgoeshere" \
//  -H "X-AVOSCloud-Application-Key: restapikeygoeshere" \
//  -H "Content-Type: application/json" \
//  -d '{"username":"usernamegoeshere","password":"passwordgoeshere","phone":"123-456-7890"}' \
//  https://LeanCloud.cn/1/users
procedure TLeanCloudApi.SignupUser(const AUserName, APassword: string; const AUserFields: TJSONObject;
  out ANewUser: TLogin);
var
  LResponse: TJsonObject;
  LUser: TJSONObject;
begin
  FRequest.ResetToDefaults;
  AddAuthParameters;
  FRequest.Method := TRESTRequestMethod.rmPOST;
  FRequest.Resource := sUsers;
  if AUserFields <> nil then
    LUser := AUserFields.Clone as TJSONObject
  else
    LUser := TJSONObject.Create;
  try
    LUser.AddPair('username', AUserName); // Do not localize
    LUser.AddPair('password', APassword); // Do not localize
    FRequest.AddBody(LUser);
    FRequest.Execute;
    CheckForResponseError([201]);
    LResponse := FRequest.Response.JSONValue as TJSONObject;
    ANewUser := LoginFromObject(AUserName, LResponse);
  finally
    LUser.Free;
  end;
end;

//curl -X PUT \
//  -H "X-AVOSCloud-Application-Id: appidgoeshere" \
//  -H "X-AVOSCloud-Application-Key: restapikeygoeshere" \
//  -H "X-AVOSCloud-Session-Token: sessiontokengoeshere" \
//  -H "Content-Type: application/json" \
//  -d '{"phone":"123-456-7890"}' \
//  https://LeanCloud.cn/1/users/g1234567
procedure TLeanCloudApi.UpdateUser(const ASessionID, AObjectID: string; const AUserObject: TJSONObject; out AUpdatedAt: TUpdatedAt);
var
  LResponse: TJSONObject;
begin
  FRequest.ResetToDefaults;
  // Check session or master
  if ASessionID <> '' then
    AddSessionToken(ConnectionInfo.RestApiKey, ASessionID)
  else
    AddAuthParameters;
  PutResource(sUsers + '/' + AObjectID, AUserObject, False);
  LResponse := FRequest.Response.JSONValue as TJSONObject;
  // '{"updatedAt":"2013-10-16T20:21:57.326Z"}'
  AUpdatedAt := UpdatedAtFromObject('', AObjectID, LResponse);
end;

procedure TLeanCloudApi.UpdateUser(const AObjectID: string; const AUserObject: TJSONObject; out AUpdatedAt: TUpdatedAt);
begin
  UpdateUser('', AObjectID, AUserObject, AUpdatedAt);
end;

procedure TLeanCloudApi.UpdateUser(const ALogin: TLogin; const AUserObject: TJSONObject; out AUpdatedAt: TUpdatedAt);
begin
  UpdateUser(ALogin.SessionToken, ALogin.User.ObjectID, AUserObject, AUpdatedAt);
end;

//curl -X GET \
//  -H "X-AVOSCloud-Application-Id: appidgoeshere" \
//  -H "X-AVOSCloud-Application-Key: restapikeygoeshere" \
//  https://LeanCloud.cn/1/users
procedure TLeanCloudApi.QueryUsers(const AQuery: array of string; const AJSONArray: TJSONArray);
begin
  QueryResource(sUsers, AQuery, AJSONArray, True);
end;

procedure TLeanCloudApi.QueryUsers(const AQuery: array of string; const AJSONArray: TJSONArray; out AUsers: TArray<TUser>);
var
  LJSONValue: TJSONValue;
  LList: TList<TUser>;
  LUser: TUser;
begin
  QueryResource(sUsers, AQuery, AJSONArray, True);
  LList := TList<TUser>.Create;
  try
    for LJSONValue in AJSONArray do
    begin
      if LJSONValue is TJSONObject then
      begin
        LUser := UserFromObject(TJSONObject(LJSONValue));
        LList.Add(LUser);
      end
      else
        raise ELeanCloudAPIError.Create(sJSONObjectExpected);
    end;
    AUsers := LList.ToArray;
  finally
    LList.Free;
  end;
end;


       
////curl -X POST \
////  -H "X-AVOSCloud-Application-Id: appidgoeshere" \
////  -H "X-AVOSCloud-Application-Key: restapikeygoeshere" \
////  -H "Content-Type: application/json" \
////  -d '{"email":"coolguy@iloveapps.com"}' \
////  https://LeanCloud.cn/1/requestPasswordReset
//function TLeanCloudApi.ResetUserPassword(const AUserName, APassword: string): IBackendUser;
//begin
//end;

{ ELeanCloudException }

constructor ELeanCloudAPIError.Create(ACode: Integer; const AError: string);
begin
  FCode := ACode;
  FError := AError;
  inherited CreateFmt(sFormatLeanCloudError, [Self.Error, Self.Code]);
end;

{ TLeanCloudApi.TConnectionInfo }

constructor TLeanCloudApi.TConnectionInfo.Create(const AApiVersion, AApplicationID: string);
begin
  ApiVersion := AApiVersion;
  ApplicationID := AApplicationID;
end;

{ TLeanCloudApi.TObjectID }

constructor TLeanCloudApi.TObjectID.Create(const ABackendClassName: string;
  AObjectID: string);
begin
  FBackendClassName := ABackendClassName;
  FObjectID := AObjectID;
end;

{ TLeanCloudApi.TFileID }

constructor TLeanCloudApi.TFile.Create(const AName: string);
begin
  FName := AName;
end;

{ TLeanCloudApi.TUserID }

constructor TLeanCloudApi.TUser.Create(const AUserName: string);
begin
  FUserName := AUserName;
end;

{ TLeanCloudApi.TLogin }

constructor TLeanCloudApi.TLogin.Create(const ASessionToken: string;
  const AUser: TUser);
begin
  FSessionToken := ASessionToken;
  FUser := AUser;
end;

{ TLeanCloudApi.TUpdatedAt}

constructor TLeanCloudApi.TUpdatedAt.Create(const ABackendClassName, AObjectID: string; AUpdatedAt: TDateTime);
begin
  FUpdatedAt := AUpdatedAt;
  FBackendClassName := ABackendClassName;
  FObjectID := AObjectID;
end;

end.
