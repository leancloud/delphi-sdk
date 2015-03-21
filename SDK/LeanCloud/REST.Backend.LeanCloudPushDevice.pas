{*******************************************************}
{                                                       }
{             Delphi REST Client Framework              }
{                                                       }
{ Copyright(c) 2015 yuanpeng                            }
{                                                       }
{*******************************************************}
unit REST.Backend.LeanCloudPushDevice;

{$HPPEMIT LINKUNIT}
interface

uses
  System.Classes,
  System.SysUtils,
  System.JSON,
  System.PushNotification,
  REST.Backend.Providers,
  REST.Backend.PushTypes,
  REST.Backend.LeanCloudProvider,
  REST.Backend.LeanCloudApi,
  REST.Backend.Exception;

type


{$IFDEF IOS}
{$DEFINE PUSH}
{$ENDIF}
{$IFDEF ANDROID}
{$DEFINE PUSH}
{$ENDIF}

  TLeanCloudPushDeviceAPI = class(TLeanCloudServiceAPIAuth, IBackendPushDeviceApi)
  private const
    sLeanCloud = 'LeanCloud';
  private
    FGCMAppID: String;
    FInstallationID: string; // GUID
{$IFDEF PUSH}
    FInstallationObjectID: string;
{$ENDIF}
  protected
    { IBackendPushDeviceAPI }
    function GetPushService: TPushService; // May raise exception
    function HasPushService: Boolean;
    procedure RegisterDevice(AOnRegistered: TDeviceRegisteredAtProviderEvent);
    procedure UnregisterDevice;
  end;

  TLeanCloudPushDeviceService = class(TLeanCloudBackendService<TLeanCloudPushDeviceAPI>, IBackendService, IBackendPushDeviceService)
  protected
    function CreateBackendApi: TLeanCloudPushDeviceAPI; override;
    { IBackendPushDeviceService }
    function CreatePushDeviceApi: IBackendPushDeviceApi;
    function GetPushDeviceApi: IBackendPushDeviceApi;
  end;

  ELeanCloudPushNotificationError = class(EBackendServiceError); 

implementation

uses
  System.Generics.Collections,
  System.TypInfo,
  REST.Backend.Consts,
  REST.Backend.ServiceFactory
{$IFDEF PUSH}
{$IFDEF IOS}
  ,FMX.PushNotification.IOS // inject IOS push provider
{$ENDIF}
{$IFDEF ANDROID}
  ,FMX.PushNotification.Android // inject GCM push provider
{$ENDIF}
{$ENDIF}
  ;

{ TLeanCloudPushDeviceService }

function TLeanCloudPushDeviceService.CreatePushDeviceApi: IBackendPushDeviceApi;
begin
  Result := CreateBackendApi;
end;

function TLeanCloudPushDeviceService.CreateBackendApi: TLeanCloudPushDeviceAPI;
begin
  Result := inherited;
  if ConnectionInfo <> nil then
    Result.FInstallationID := ConnectionInfo.AndroidPush.InstallationID
  else
    Result.FInstallationID := '';
  Result.FGCMAppID := '1076345567071';  // Same ID for all clients
end;

function TLeanCloudPushDeviceService.GetPushDeviceApi: IBackendPushDeviceApi;
begin
  EnsureBackendApi;
  Result := FBackendAPI;
end;

{ TLeanCloudPushDeviceAPI }

function GetDeviceID(const AService: TPushService): string;
begin
  Result := AService.DeviceIDValue[TPushService.TDeviceIDNames.DeviceID];
end;

function GetDeviceName: string;
begin
{$IFDEF IOS}
  Result := 'ios';
{$ENDIF}
{$IFDEF ANDROID}
  Result := 'android';
{$ENDIF}
{$IFDEF MSWINDOWS}
  Result := 'windows';
{$ENDIF}
end;

function GetServiceName: string;
begin
{$IFDEF PUSH}
{$IFDEF IOS}
  Result := TPushService.TServiceNames.APS;
{$ENDIF}
{$IFDEF ANDROID}
  Result := TPushService.TServiceNames.GCM;
{$ENDIF}
{$IFDEF MSWINDOWS}
  Result := '';
{$ENDIF}
{$ENDIF}
end;

function GetService(const AServiceName: string): TPushService;
begin
  Result := TPushServiceManager.Instance.GetServiceByName(AServiceName);
end;

procedure GetRegistrationInfo(const APushService: TPushService;
  out ADeviceID, ADeviceToken: string);
begin
  ADeviceID := APushService.DeviceIDValue[TPushService.TDeviceIDNames.DeviceID];
  ADeviceToken := APushService.DeviceTokenValue[TPushService.TDeviceTokenNames.DeviceToken];

  if ADeviceID = ''  then
    raise ELeanCloudPushNotificationError.Create(sDeviceIDUnavailable); 

  if ADeviceToken = ''  then
    raise ELeanCloudPushNotificationError.Create(sDeviceTokenUnavailable);   
end;

function TLeanCloudPushDeviceAPI.GetPushService: TPushService;
var
  LServiceName: string;
  LDeviceName: string;
  LService: TPushService;
begin
  LDeviceName := GetDeviceName;
  Assert(LDeviceName <> '');
  LServiceName := GetServiceName;
  if LServiceName = '' then
    raise ELeanCloudPushNotificationError.CreateFmt(sPushDeviceNoPushService, [sLeanCloud, LDeviceName]);

  LService := GetService(LServiceName);
  if LService = nil then
    raise ELeanCloudPushNotificationError.CreateFmt(sPushDevicePushServiceNotFound, [sLeanCloud, LServiceName]);
  if LService.ServiceName = TPushService.TServiceNames.GCM then
    if not (LService.Status in [TPushService.TStatus.Started]) then
    begin
      if FGCMAppID = '' then
        raise ELeanCloudPushNotificationError.Create(sPushDeviceGCMAppIDBlank);
      LService.AppProps[TPushService.TAppPropNames.GCMAppID] := FGCMAppID;
    end;
  Result := LService;
end;

function TLeanCloudPushDeviceAPI.HasPushService: Boolean;
var
  LServiceName: string;
begin
  LServiceName := GetServiceName;
  Result := (LServiceName <> '') and (GetService(LServiceName) <> nil);
end;

procedure TLeanCloudPushDeviceAPI.RegisterDevice(
  AOnRegistered: TDeviceRegisteredAtProviderEvent);
var
  LDeviceName: string;
  LServiceName: string;
{$IFDEF PUSH}
  LDeviceID: string;
  LDeviceToken: string;
  ANewObject: TLeanCloudAPI.TObjectID;
  AUpdateObject: TLeanCloudAPI.TUpdatedAt;
  LJSONObject: TJSONObject;
  LChannels: TArray<string>;
{$ENDIF}
begin
  LDeviceName := GetDeviceName;
  Assert(LDeviceName <> '');
  LServiceName := GetServiceName;
  if LServiceName = '' then
    raise ELeanCloudPushNotificationError.CreateFmt(sPushDeviceNoPushService, [sLeanCloud, LDeviceName]);

// Badge and Channel properties
{$IFDEF PUSH}
  LChannels := nil;         
  GetRegistrationInfo(GetPushService, LDeviceID, LDeviceToken);    // May raise exception
{$IFDEF IOS}
                                  
  LJSONObject := LeanCloudApi.CreateIOSInstallationObject(LDeviceToken, 0, LChannels);
{$ELSE}
  LJSONObject := LeanCloudApi.CreateAndroidInstallationObject(FInstallationID, LDeviceToken, LChannels);
{$ENDIF}
  try
                                  
    if FInstallationObjectID <> '' then
    begin
      LeanCloudApi.UpdateInstallation(FInstallationObjectID, LJSONObject, AUpdateObject);
      if Assigned(AOnRegistered) then
        AOnRegistered(GetPushService);
    end
    else
    begin
      LeanCloudApi.UploadInstallation(LJSONObject, ANewObject);
      FInstallationObjectID := ANewObject.ObjectID;
      if Assigned(AOnRegistered) then
        AOnRegistered(GetPushService);
    end;
  finally
    LJSONObject.Free;
  end;
{$ELSE}
  raise ELeanCloudPushNotificationError.CreateFmt(sPushDeviceNoPushService, [sLeanCloud, LDeviceName]);
{$ENDIF}
end;


procedure TLeanCloudPushDeviceAPI.UnregisterDevice;
var
  LDeviceName: string;
  LServiceName: string;
begin
  LServiceName := '';
  LDeviceName := GetDeviceName;
  Assert(LDeviceName <> '');
{$IFDEF PUSH}
  if FInstallationObjectID = '' then
    raise ELeanCloudPushNotificationError.Create(sPushDeviceLeanCloudInstallationIDBlankDelete);
  LeanCloudApi.DeleteInstallation(FInstallationObjectID);
{$ELSE}
  raise ELeanCloudPushNotificationError.CreateFmt(sPushDeviceNoPushService, [sLeanCloud, LDeviceName]);
{$ENDIF}
end;

type
  TLeanCloudPushDeviceServiceFactory = class(TProviderServiceFactory<IBackendPushDeviceService>)
  protected
    function CreateService(const AProvider: IBackendProvider; const IID: TGUID): IBackendService; override;
  public
    constructor Create;
  end;

constructor TLeanCloudPushDeviceServiceFactory.Create;
begin
  inherited Create(TCustomLeanCloudProvider.ProviderID, 'REST.Backend.LeanCloudPushDevice');  // Do not localize
end;

function TLeanCloudPushDeviceServiceFactory.CreateService(const AProvider: IBackendProvider;
  const IID: TGUID): IBackendService;
begin
  Result := TLeanCloudPushDeviceService.Create(AProvider);
end;

var
  FFactory: TLeanCloudPushDeviceServiceFactory;

initialization
  FFactory := TLeanCloudPushDeviceServiceFactory.Create;
  FFactory.Register;
finalization
  FFactory.Unregister;
  FFactory.Free;

end.
