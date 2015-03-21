{*******************************************************}
{                                                       }
{             Delphi REST Client Framework              }
{                                                       }
{ Copyright(c) 2015 yuanpeng                            }
{                                                       }
{*******************************************************}
{$HPPEMIT LINKUNIT}
unit REST.Backend.LeanCloudProvider;

interface

uses System.Classes, System.Generics.Collections, REST.Backend.Providers,
  REST.Backend.LeanCloudAPI, REST.Client, REST.Backend.ServiceTypes,
  REST.Backend.MetaTypes;

type

  TCustomLeanCloudConnectionInfo = class(TComponent)
  public type
    TNotifyList = class
    private
      FList: TList<TNotifyEvent>;
      procedure Notify(Sender: TObject);
    public
      constructor Create;
      destructor Destroy; override;
      procedure Add(const ANotify: TNotifyEvent);
      procedure Remove(const ANotify: TNotifyEvent);
    end;
    TAndroidPush = class(TPersistent)
    private
      FInstallationID: string;
      FHaveID: Boolean;
      procedure ReadBlank(Reader: TReader);
      procedure WriteBlank(Writer: TWriter);
      function GetInstallationID: string;
      procedure SetInstallationID(const Value: string);
    protected
      procedure AssignTo(AValue: TPersistent); override;
      procedure DefineProperties(Filer: TFiler); override;
    public
      class function NewInstallationID: string;
    published
      property InstallationID: string read GetInstallationID write SetInstallationID stored True;
    end;
  private
    FConnectionInfo: TLeanCloudApi.TConnectionInfo;
    FNotifyOnChange: TNotifyList;
    FAndroidPush: TAndroidPush;
    procedure SetApiVersion(const Value: string);
    procedure SetApplicationID(const Value: string);
    procedure SetRestApiKey(const Value: string);
    procedure SetMasterKey(const Value: string);
    function GetApiVersion: string;
    function GetRestApiKey: string;
    function GetMasterKey: string;
    function GetApplicationID: string;
    procedure SetAndroidPush(const Value: TAndroidPush);
    function GetProxyPassword: string;
    function GetProxyPort: integer;
    function GetProxyServer: string;
    function GetProxyUsername: string;
    procedure SetProxyPassword(const Value: string);
    procedure SetProxyPort(const Value: integer);
    procedure SetProxyServer(const Value: string);
    procedure SetProxyUsername(const Value: string);
  protected
    procedure DoChanged; virtual;
    property NotifyOnChange: TNotifyList read FNotifyOnChange;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure UpdateApi(const ALeanCloudApi: TLeanCloudApi);
                                  
    property ApiVersion: string read GetApiVersion write SetApiVersion;
    property ApplicationID: string read GetApplicationID write SetApplicationID;
    property RestApiKey: string read GetRestApiKey write SetRestApiKey;
    property MasterKey: string read GetMasterKey write SetMasterKey;
    property AndroidPush: TAndroidPush read FAndroidPush write SetAndroidPush;
    property ProxyPassword: string read GetProxyPassword write SetProxyPassword;
    property ProxyPort: integer read GetProxyPort write SetProxyPort default 0;
    property ProxyServer: string read GetProxyServer write SetProxyServer;
    property ProxyUsername: string read GetProxyUsername write SetProxyUsername;
  end;

  TCustomLeanCloudProvider = class(TCustomLeanCloudConnectionInfo, IBackendProvider, IRESTIPComponent)
  public const
    ProviderID = 'LeanCloud';
  protected
    { IBackendProvider }
    function GetProviderID: string;
  end;

  [ComponentPlatformsAttribute(pidWin32 or pidWin64 or pidOSX32 or pidiOSSimulator or pidiOSDevice or pidAndroid)]
  TLeanCloudProvider = class(TCustomLeanCloudProvider)
  published
    property ApiVersion;
    property ApplicationID;
    property RestApiKey;
    property MasterKey;
    // LeanCloud/GCM not currently supported
    property AndroidPush;
    property ProxyPassword;
    property ProxyPort;
    property ProxyServer;
    property ProxyUsername;
  end;

  TLeanCloudBackendService = class(TInterfacedObject)
  private
    FConnectionInfo: TCustomLeanCloudConnectionInfo;
    procedure SetConnectionInfo(const Value: TCustomLeanCloudConnectionInfo);
    procedure OnConnectionChanged(Sender: TObject);
  protected
    procedure DoAfterConnectionChanged; virtual;
    property ConnectionInfo: TCustomLeanCloudConnectionInfo read FConnectionInfo write SetConnectionInfo;
  public
    constructor Create(const AProvider: IBackendProvider); virtual;
    destructor Destroy; override;
  end;

  // Use to access TLeanCloudAPI from a component
  //
  // if Supports(BackendStorage1.ProviderService, IGetLeanCloudAPI, LIntf) then
  //    LLeanCloudAPI := LIntf.LeanCloudAPI;
  IGetLeanCloudAPI = interface
    ['{9EFB309D-6A53-4F3B-8B7F-D9E7D92998E8}']
    function GetLeanCloudAPI: TLeanCloudAPI;
    property LeanCloudAPI: TLeanCloudAPI read GetLeanCloudApi;
  end;

  TLeanCloudServiceAPI = class(TInterfacedObject, IBackendAPI, IGetLeanCloudAPI)
  private
    FLeanCloudAPI: TLeanCloudAPI;
    { IGetLeanCloudAPI }
    function GetLeanCloudAPI: TLeanCloudAPI;
  protected
    property LeanCloudAPI: TLeanCloudAPI read FLeanCloudAPI;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  TLeanCloudServiceAPIAuth = class(TLeanCloudServiceAPI, IBackendAuthenticationApi)
  protected
    { IBackendAuthenticationApi }
    procedure Login(const ALogin: TBackendEntityValue);
    procedure Logout;
    procedure SetDefaultAuthentication(ADefaultAuthentication: TBackendDefaultAuthentication);
    function GetDefaultAuthentication: TBackendDefaultAuthentication;
    procedure SetAuthentication(AAuthentication: TBackendAuthentication);
    function GetAuthentication: TBackendAuthentication;
  end;

  TLeanCloudBackendService<TAPI: TLeanCloudServiceAPI, constructor> = class(TLeanCloudBackendService, IGetLeanCloudAPI)
  private
    FBackendAPI: TAPI;
    FBackendAPIIntf: IInterface;
    procedure ReleaseBackendApi;
    { IGetLeanCloudAPI }
    function GetLeanCloudAPI: TLeanCloudAPI;
  protected
    function CreateBackendApi: TAPI; virtual;
    procedure EnsureBackendApi;
    procedure DoAfterConnectionChanged; override;
  end;

procedure Register;

implementation

uses System.SysUtils, REST.Backend.LeanCloudMetaTypes, System.TypInfo, REST.Backend.Consts;

{ TCustomLeanCloudProvider }

procedure Register;
begin
  RegisterComponents('BAAS Client', [TLeanCloudProvider]);
end;

function TCustomLeanCloudProvider.GetProviderID: string;
begin
  Result := ProviderID;
end;

{ TCustomLeanCloudConnectionInfo }

constructor TCustomLeanCloudConnectionInfo.Create(AOwner: TComponent);
begin
  inherited;
  FConnectionInfo := TLeanCloudApi.TConnectionInfo.Create(TLeanCloudApi.cDefaultApiVersion, '');
  FNotifyOnChange := TNotifyList.Create;
  FAndroidPush := TAndroidPush.Create;
end;

destructor TCustomLeanCloudConnectionInfo.Destroy;
begin
  FAndroidPush.Free;
  inherited;
  FNotifyOnChange.Free;
end;

procedure TCustomLeanCloudConnectionInfo.DoChanged;
begin
  FNotifyOnChange.Notify(Self);
end;

function TCustomLeanCloudConnectionInfo.GetApiVersion: string;
begin
  Result := FConnectionInfo.ApiVersion;
end;

function TCustomLeanCloudConnectionInfo.GetApplicationID: string;
begin
  Result := FConnectionInfo.ApplicationID;
end;

function TCustomLeanCloudConnectionInfo.GetRestApiKey: string;
begin
  Result := FConnectionInfo.RestApiKey;
end;

function TCustomLeanCloudConnectionInfo.GetMasterKey: string;
begin
  Result := FConnectionInfo.MasterKey;
end;

function TCustomLeanCloudConnectionInfo.GetProxyPassword: string;
begin
  Result := FConnectionInfo.ProxyPassword;
end;

function TCustomLeanCloudConnectionInfo.GetProxyPort: integer;
begin
  Result := FConnectionInfo.ProxyPort;
end;

function TCustomLeanCloudConnectionInfo.GetProxyServer: string;
begin
  Result := FConnectionInfo.ProxyServer;
end;

function TCustomLeanCloudConnectionInfo.GetProxyUsername: string;
begin
  Result := FConnectionInfo.ProxyUsername;
end;

procedure TCustomLeanCloudConnectionInfo.SetAndroidPush(const Value: TAndroidPush);
begin
  FAndroidPush.Assign(Value);
end;

procedure TCustomLeanCloudConnectionInfo.SetApiVersion(const Value: string);
begin
  if Value <> ApiVersion then
  begin
    FConnectionInfo.ApiVersion := Value;
    DoChanged;
  end;
end;

procedure TCustomLeanCloudConnectionInfo.SetApplicationID(const Value: string);
begin
  if Value <> ApplicationID then
  begin
    FConnectionInfo.ApplicationID := Value;
    DoChanged;
  end;
end;

procedure TCustomLeanCloudConnectionInfo.SetRestApiKey(const Value: string);
begin
  if Value <> RestApiKey then
  begin
    FConnectionInfo.RestApiKey := Value;
    DoChanged;
  end;
end;

procedure TCustomLeanCloudConnectionInfo.SetMasterKey(const Value: string);
begin
  if Value <> MasterKey then
  begin
    FConnectionInfo.MasterKey := Value;
    DoChanged;
  end;
end;

procedure TCustomLeanCloudConnectionInfo.SetProxyPassword(const Value: string);
begin
  if Value <> ProxyPassword then
  begin
    FConnectionInfo.ProxyPassword := Value;
    DoChanged;
  end;
end;

procedure TCustomLeanCloudConnectionInfo.SetProxyPort(const Value: integer);
begin
  if Value <> ProxyPort then
  begin
    FConnectionInfo.ProxyPort := Value;
    DoChanged;
  end;
end;

procedure TCustomLeanCloudConnectionInfo.SetProxyServer(const Value: string);
begin
  if Value <> ProxyServer then
  begin
    FConnectionInfo.ProxyServer := Value;
    DoChanged;
  end;
end;

procedure TCustomLeanCloudConnectionInfo.SetProxyUsername(const Value: string);
begin
  if Value <> ProxyUsername then
  begin
    FConnectionInfo.ProxyUsername := Value;
    DoChanged;
  end;
end;

procedure TCustomLeanCloudConnectionInfo.UpdateApi(const ALeanCloudApi: TLeanCloudApi);
begin
  ALeanCloudApi.ConnectionInfo := FConnectionInfo;
end;

{ TCustomLeanCloudConnectionInfo.TNotifyList }

procedure TCustomLeanCloudConnectionInfo.TNotifyList.Add(const ANotify: TNotifyEvent);
begin
  Assert(not FList.Contains(ANotify));
  if not FList.Contains(ANotify) then
    FList.Add(ANotify);
end;

constructor TCustomLeanCloudConnectionInfo.TNotifyList.Create;
begin
  FList := TList<TNotifyEvent>.Create;
end;

destructor TCustomLeanCloudConnectionInfo.TNotifyList.Destroy;
begin
  FList.Free;
  inherited;
end;

procedure TCustomLeanCloudConnectionInfo.TNotifyList.Notify(Sender: TObject);
var
  LProc: TNotifyEvent;
begin
  for LProc in FList do
    LProc(Sender);
end;

procedure TCustomLeanCloudConnectionInfo.TNotifyList.Remove(
  const ANotify: TNotifyEvent);
begin
  Assert(FList.Contains(ANotify));
  FList.Remove(ANotify);
end;

{ TLeanCloudServiceAPI }

constructor TLeanCloudServiceAPI.Create;
begin
  FLeanCloudAPI := TLeanCloudAPI.Create(nil);
end;

destructor TLeanCloudServiceAPI.Destroy;
begin
  FLeanCloudAPI.Free;
  inherited;
end;

function TLeanCloudServiceAPI.GetLeanCloudAPI: TLeanCloudAPI;
begin
  Result := FLeanCloudAPI;
end;

{ TLeanCloudBackendService<TAPI> }

function TLeanCloudBackendService<TAPI>.CreateBackendApi: TAPI;
begin
  Result := TAPI.Create;
  if ConnectionInfo <> nil then
    ConnectionInfo.UpdateAPI(Result.FLeanCloudAPI)
  else
    Result.FLeanCloudAPI.ConnectionInfo := TLeanCloudAPI.EmptyConnectionInfo;
end;

procedure TLeanCloudBackendService<TAPI>.EnsureBackendApi;
begin
  if FBackendAPI = nil then
  begin
    FBackendAPI := CreateBackendApi;
    FBackendAPIIntf := FBackendAPI; // Reference
  end;
end;

function TLeanCloudBackendService<TAPI>.GetLeanCloudAPI: TLeanCloudAPI;
begin
  EnsureBackendApi;
  if FBackendAPI <> nil then
    Result := FBackendAPI.FLeanCloudAPI;
end;

procedure TLeanCloudBackendService<TAPI>.ReleaseBackendApi;
begin
  FBackendAPI := nil;
  FBackendAPIIntf := nil;
end;

procedure TLeanCloudBackendService<TAPI>.DoAfterConnectionChanged;
begin
  ReleaseBackendApi;
end;

{ TLeanCloudBackendService }

constructor TLeanCloudBackendService.Create(const AProvider: IBackendProvider);
begin
  if AProvider is TCustomLeanCloudConnectionInfo then
    ConnectionInfo := TCustomLeanCloudConnectionInfo(AProvider)
  else
    raise EArgumentException.Create(sWrongProvider);
end;

destructor TLeanCloudBackendService.Destroy;
begin
  if Assigned(FConnectionInfo) then
    FConnectionInfo.NotifyOnChange.Remove(OnConnectionChanged);
  inherited;
end;

procedure TLeanCloudBackendService.DoAfterConnectionChanged;
begin
//
end;

procedure TLeanCloudBackendService.OnConnectionChanged(Sender: TObject);
begin
  DoAfterConnectionChanged;
end;

procedure TLeanCloudBackendService.SetConnectionInfo(
  const Value: TCustomLeanCloudConnectionInfo);
begin
  if FConnectionInfo <> nil then
    FConnectionInfo.NotifyOnChange.Remove(OnConnectionChanged);
  FConnectionInfo := Value;
  if FConnectionInfo <> nil then
    FConnectionInfo.NotifyOnChange.Add(OnConnectionChanged);
  OnConnectionChanged(Self);
end;

{ TCustomLeanCloudConnectionInfo.TAndroidProps }

procedure TCustomLeanCloudConnectionInfo.TAndroidPush.AssignTo(
  AValue: TPersistent);
begin
  if AValue is TAndroidPush then
    Self.FInstallationID := TAndroidPush(AValue).FInstallationID
  else
    inherited;
end;

procedure TCustomLeanCloudConnectionInfo.TAndroidPush.DefineProperties(Filer: TFiler);
begin
  inherited DefineProperties(Filer);
  Filer.DefineProperty('BlankID', ReadBlank, WriteBlank,
    FInstallationID = '');
end;

function TCustomLeanCloudConnectionInfo.TAndroidPush.GetInstallationID: string;
begin
  if not FHaveID then
  begin
    FHaveID := True;
    if FInstallationID = '' then
      FInstallationID := NewInstallationID;
  end;
  Result := FInstallationID;
end;

procedure TCustomLeanCloudConnectionInfo.TAndroidPush.WriteBlank(Writer: TWriter);
begin
  Writer.WriteBoolean(True);
end;

procedure TCustomLeanCloudConnectionInfo.TAndroidPush.ReadBlank(Reader: TReader);
begin
  Reader.ReadBoolean;
  FHaveID := True;
end;

procedure TCustomLeanCloudConnectionInfo.TAndroidPush.SetInstallationID(
  const Value: string);
begin
  FHaveID := True;
  FInstallationID := Value;
end;

{ TLeanCloudServiceAPIAuth }

function TLeanCloudServiceAPIAuth.GetAuthentication: TBackendAuthentication;
begin
  case LeanCloudAPI.Authentication of
    TLeanCloudApi.TAuthentication.Default:
      Result := TBackendAuthentication.Default;
    TLeanCloudApi.TAuthentication.MasterKey:
      Result := TBackendAuthentication.Root;
    TLeanCloudApi.TAuthentication.APIKey:
       Result := TBackendAuthentication.Application;
   TLeanCloudApi.TAuthentication.Session:
       Result := TBackendAuthentication.Session;
  else
    Assert(False);
    Result := TBackendAuthentication.Default;
  end;
end;

function TLeanCloudServiceAPIAuth.GetDefaultAuthentication: TBackendDefaultAuthentication;
begin
  case LeanCloudAPI.DefaultAuthentication of
    TLeanCloudApi.TDefaultAuthentication.APIKey:
      Result := TBackendDefaultAuthentication.Application;
    TLeanCloudApi.TDefaultAuthentication.MasterKey:
      Result := TBackendDefaultAuthentication.Root;
    TLeanCloudApi.TDefaultAuthentication.Session:
      Result := TBackendDefaultAuthentication.Session;
  else
    Assert(False);
    Result := TBackendDefaultAuthentication.Root;
  end;
end;

procedure TLeanCloudServiceAPIAuth.Login(const ALogin: TBackendEntityValue);
var
  LMetaLogin: TMetaLogin;
begin
  if ALogin.Data is TMetaLogin then
  begin
    LMetaLogin := TMetaLogin(ALogin.Data);
    LeanCloudAPI.Login(LMetaLogin.Login);
  end
  else
    raise EArgumentException.Create(sParameterNotLogin);  // Do not localize
end;

procedure TLeanCloudServiceAPIAuth.Logout;
begin
  LeanCloudAPI.Logout;
end;

procedure TLeanCloudServiceAPIAuth.SetAuthentication(
  AAuthentication: TBackendAuthentication);
begin
  case AAuthentication of
    TBackendAuthentication.Default:
      LeanCloudAPI.Authentication := TLeanCloudApi.TAuthentication.Default;
    TBackendAuthentication.Root:
      LeanCloudAPI.Authentication := TLeanCloudApi.TAuthentication.MasterKey;
    TBackendAuthentication.Application:
      LeanCloudAPI.Authentication := TLeanCloudApi.TAuthentication.APIKey;
    TBackendAuthentication.Session:
      LeanCloudAPI.Authentication := TLeanCloudApi.TAuthentication.Session;
    TBackendAuthentication.None:
      LeanCloudAPI.Authentication := TLeanCloudApi.TAuthentication.None;
    TBackendAuthentication.User:
      raise ELeanCloudAPIError.CreateFmt(sAuthenticationNotSupported, [
        System.TypInfo.GetEnumName(TypeInfo(TBackendAuthentication), Integer(AAuthentication))]);
  else
    Assert(False);
  end;

end;

procedure TLeanCloudServiceAPIAuth.SetDefaultAuthentication(
  ADefaultAuthentication: TBackendDefaultAuthentication);
begin
  case ADefaultAuthentication of
    TBackendDefaultAuthentication.Root:
      LeanCloudAPI.DefaultAuthentication := TLeanCloudApi.TDefaultAuthentication.MasterKey;
    TBackendDefaultAuthentication.Application:
      LeanCloudAPI.DefaultAuthentication := TLeanCloudApi.TDefaultAuthentication.APIKey;
    TBackendDefaultAuthentication.Session:
      LeanCloudAPI.DefaultAuthentication := TLeanCloudApi.TDefaultAuthentication.Session;
    TBackendDefaultAuthentication.None:
      LeanCloudAPI.DefaultAuthentication := TLeanCloudApi.TDefaultAuthentication.None;
    TBackendDefaultAuthentication.User:
      raise ELeanCloudAPIError.CreateFmt(sAuthenticationNotSupported, [
        System.TypInfo.GetEnumName(TypeInfo(TBackendDefaultAuthentication), Integer(ADefaultAuthentication))]);
  else
    Assert(False);
  end;
end;

class function TCustomLeanCloudConnectionInfo.TAndroidPush.NewInstallationID: string;
var
  LGuid: TGuid;
begin
  CreateGUID(LGuid);
  Result := GUIDToString(LGuid);
  // Strip '{','}'
  Result := Result.Substring(1, Result.Length - 2);
end;

initialization
  TBackendProviders.Instance.Register(TCustomLeanCloudProvider.ProviderID, 'LeanCloud');      // Do not localize
finalization
  TBackendProviders.Instance.UnRegister(TCustomLeanCloudProvider.ProviderID);
end.
