{*******************************************************}
{                                                       }
{             Delphi REST Client Framework              }
{                                                       }
{ Copyright(c) 2015 yuanpeng                            }
{                                                       }
{*******************************************************}
{$HPPEMIT LINKUNIT}
unit REST.Backend.LeanCloudServices;

interface

uses
  System.Classes,
  System.SysUtils,
  System.JSON,
  REST.Backend.Providers,
  REST.Backend.PushTypes,
  REST.Backend.ServiceTypes,
  REST.Backend.MetaTypes,
  REST.Backend.LeanCloudProvider,
  REST.Backend.LeanCloudApi;

type
  // Files service

  TLeanCloudFilesAPI = class(TLeanCloudServiceAPIAuth, IBackendFilesApi)
  protected
    { IBackendFilesAPI }
    function GetMetaFactory: IBackendMetaFactory;
    procedure UploadFile(const AFileName: string; const AContentType: string;
      out AFile: TBackendEntityValue); overload;
    procedure UploadFile(const AFileName: string; const AStream: TStream; const AContentType: string;
      out AFile: TBackendEntityValue); overload;
    function DeleteFile(const AFile: TBackendEntityValue): Boolean;
  end;

  TLeanCloudFilesService = class(TLeanCloudBackendService<TLeanCloudFilesAPI>, IBackendService, IBackendFilesService)
  protected
    { IBackendFilesService }
    function CreateFilesApi: IBackendFilesApi;
    function GetFilesApi: IBackendFilesApi;
  end;

  // Push service

  TLeanCloudPushAPI = class(TLeanCloudServiceAPIAuth, IBackendPushApi)
  protected
    { IBackendPushAPI }
    procedure PushBroadcast(const AData: TPushData);
  end;

  TLeanCloudPushService = class(TLeanCloudBackendService<TLeanCloudPushAPI>, IBackendService, IBackendPushService)
  protected
    { IBackendPushService }
    function CreatePushApi: IBackendPushApi;
    function GetPushApi: IBackendPushApi;
  end;

  // Query service

  TLeanCloudQueryAPI = class(TLeanCloudServiceAPIAuth, IBackendQueryApi)
  protected
    { IBackendQueryAPI }
    procedure GetServiceNames(out ANames: TArray<string>);
    function GetMetaFactory: IBackendMetaFactory;
    procedure Query(const AClass: TBackendMetaClass; const AQuery: array of string; const AJSONArray: TJSONArray); overload;
    procedure Query(const AClass: TBackendMetaClass; const AQuery: array of string;
      const AJSONArray: TJSONArray; out AObjects: TArray<TBackendEntityValue>); overload;
  end;

  TLeanCloudQueryService = class(TLeanCloudBackendService<TLeanCloudQueryAPI>, IBackendService, IBackendQueryService)
  protected
    { IBackendQueryService }
    function CreateQueryApi: IBackendQueryApi;
    function GetQueryApi: IBackendQueryApi;
  end;

  // Users service

  TLeanCloudLoginAPI = class(TLeanCloudServiceAPIAuth, IBackendAuthApi)
  protected
    { IBackendLoginAPI }
    function GetMetaFactory: IBackendMetaFactory;
    procedure SignupUser(const AUserName, APassword: string; const AUserData: TJSONObject;
      out ACreatedObject: TBackendEntityValue);
    procedure LoginUser(const AUserName, APassword: string; AProc: TFindObjectProc); overload;
    procedure LoginUser(const AUserName, APassword: string; out AUser: TBackendEntityValue; const AJSON: TJSONArray); overload;
    function FindCurrentUser(const AObject: TBackendEntityValue; AProc: TFindObjectProc): Boolean; overload;
    function FindCurrentUser(const AObject: TBackendEntityValue; out AUser: TBackendEntityValue; const AJSON: TJSONArray): Boolean; overload;
    procedure UpdateUser(const AObject: TBackendEntityValue; const AUserData: TJSONObject; out AUpdatedObject: TBackendEntityValue);
  end;

  TLeanCloudLoginService = class(TLeanCloudBackendService<TLeanCloudLoginAPI>, IBackendService, IBackendAuthService)
  protected
    { IBackendAuthService }
    function CreateAuthApi: IBackendAuthApi;
    function GetAuthApi: IBackendAuthApi;
  end;


  // Users service

  TLeanCloudUsersAPI = class(TLeanCloudLoginApi, IBackendUsersApi)
  protected
                                                                         
    function DeleteUser(const AObject: TBackendEntityValue): Boolean; overload;
    function FindUser(const AObject: TBackendEntityValue; AProc: TFindObjectProc): Boolean; overload;
    function FindUser(const AObject: TBackendEntityValue; out AUser: TBackendEntityValue; const AJSON: TJSONArray): Boolean; overload;
    procedure UpdateUser(const AObject: TBackendEntityValue; const AUserData: TJSONObject; out AUpdatedObject: TBackendEntityValue);
    function QueryUserName(const AUserName: string; AProc: TFindObjectProc): Boolean; overload;
    function QueryUserName(const AUserName: string; out AUser: TBackendEntityValue; const AJSON: TJSONArray): Boolean; overload;
    procedure QueryUsers(const AQuery: array of string; const AJSONArray: TJSONArray); overload;
    procedure QueryUsers(const AQuery: array of string; const AJSONArray: TJSONArray; out AMetaArray: TArray<TBackendEntityValue>); overload;
  end;

  TLeanCloudUsersService = class(TLeanCloudBackendService<TLeanCloudUsersAPI>, IBackendService, IBackendUsersService)
  protected
    { IBackendUsersService }
    function CreateUsersApi: IBackendUsersApi;
    function GetUsersApi: IBackendUsersApi;
  end;

  // Storage service

  TLeanCloudStorageAPI = class(TLeanCloudServiceAPIAuth, IBackendStorageAPI)
  protected
    { IBackendStorageAPI }
    function GetMetaFactory: IBackendMetaFactory;
    procedure CreateObject(const AClass: TBackendMetaClass; const AACL, AJSON: TJSONObject;
      out ACreatedObject: TBackendEntityValue); overload;
    function DeleteObject(const AObject: TBackendEntityValue): Boolean;
    function FindObject(const AObject: TBackendEntityValue; AProc: TFindObjectProc): Boolean;
    procedure UpdateObject(const AObject: TBackendEntityValue; const AJSONObject: TJSONObject;
      out AUpdatedObject: TBackendEntityValue);
    procedure QueryObjects(const AClass: TBackendMetaClass; const AQuery: array of string; const AJSONArray: TJSONArray); overload;
    procedure QueryObjects(const AClass: TBackendMetaClass; const AQuery: array of string;
      const AJSONArray: TJSONArray; out AObjects: TArray<TBackendEntityValue>); overload;
  end;

  TLeanCloudStorageService = class(TLeanCloudBackendService<TLeanCloudStorageAPI>, IBackendService, IBackendStorageService)
  protected
    { IBackendStorageService }
    function CreateStorageApi: IBackendStorageApi;
    function GetStorageApi: IBackendStorageApi;
  end;

implementation

uses
  System.TypInfo, System.Generics.Collections, REST.Backend.ServiceFactory,
  REST.Backend.LeanCloudMetaTypes, REST.Backend.Consts, REST.Backend.Exception;

type
  TLeanCloudProviderServiceFactory<T: IBackendService> = class(TProviderServiceFactory<T>)
  var
    FMethod: TFunc<IBackendProvider, IBackendService>;
  protected
    function CreateService(const AProvider: IBackendProvider; const IID: TGUID): IBackendService; override;
  public
    constructor Create(const AMethod: TFunc<IBackendProvider, IBackendService>);
  end;

{ TLeanCloudProviderServiceFactory<T> }

constructor TLeanCloudProviderServiceFactory<T>.Create(const AMethod: TFunc<IBackendProvider, IBackendService>);
begin
  inherited Create(TCustomLeanCloudProvider.ProviderID, 'REST.Backend.LeanCloudServices');
  FMethod := AMethod;
end;

function TLeanCloudProviderServiceFactory<T>.CreateService(
  const AProvider: IBackendProvider; const IID: TGUID): IBackendService;
begin
  Result := FMethod(AProvider);
end;

{ TLeanCloudFilesService }

function TLeanCloudFilesService.CreateFilesApi: IBackendFilesApi;
begin
  Result := CreateBackendApi;
end;

function TLeanCloudFilesService.GetFilesApi: IBackendFilesApi;
begin
  EnsureBackendApi;
  Result := FBackendAPI;
end;

{ TLeanCloudPushAPI }

procedure TLeanCloudPushAPI.PushBroadcast(
  const AData: TPushData);
var
  LJSON: TJSONObject;
begin
  if AData <> nil then
  begin
    LJSON := TJSONObject.Create;
    try
      // Flat object
      AData.Extras.Save(LJSON, '');
      AData.GCM.Save(LJSON, '');
      AData.APS.Save(LJSON, '');
      if (AData.APS.Alert = '') and (AData.Message <> '') then
        AData.SaveMessage(LJSON, TPushData.TAPS.TNames.Alert);
      if (AData.GCM.Message = '') and (AData.GCM.Msg = '') and (AData.Message <> '') then
        AData.SaveMessage(LJSON, TPushData.TGCM.TNames.Message);
      LeanCloudAPI.PushBroadcast(LJSON)
    finally
      LJSON.Free;
    end;
  end
  else
    LeanCloudAPI.PushBroadcast(nil)
end;

{ TLeanCloudPushService }

function TLeanCloudPushService.CreatePushApi: IBackendPushApi;
begin
  Result := CreateBackendApi;
end;

function TLeanCloudPushService.GetPushApi: IBackendPushApi;
begin
  EnsureBackendApi;
  Result := FBackendAPI;
end;

{ TLeanCloudQueryAPI }

procedure TLeanCloudQueryAPI.GetServiceNames(out ANames: TArray<string>);
begin
  ANames := TArray<string>.Create(
    TBackendQueryServiceNames.Storage,
    TBackendQueryServiceNames.Users,
    TBackendQueryServiceNames.Installations);
end;

function TLeanCloudQueryAPI.GetMetaFactory: IBackendMetaFactory;
begin
  Result := TMetaFactory.Create;
end;

procedure TLeanCloudQueryAPI.Query(const AClass: TBackendMetaClass;
  const AQuery: array of string; const AJSONArray: TJSONArray);
begin
  if SameText(AClass.BackendDataType, TBackendQueryServiceNames.Storage) then
    LeanCloudAPI.QueryClass(
      AClass.BackendClassName, AQuery, AJSONArray)
  else if SameText(AClass.BackendDataType, TBackendQueryServiceNames.Users) then
    LeanCloudAPI.QueryUsers(
      AQuery, AJSONArray)
  else if SameText(AClass.BackendDataType, TBackendQueryServiceNames.Installations) then
    LeanCloudAPI.QueryInstallation(
      AQuery, AJSONArray)
  else
    raise EBackendServiceError.CreateFmt(sUnsupportedBackendQueryType, [AClass.BackendDataType]);
end;

procedure TLeanCloudQueryAPI.Query(const AClass: TBackendMetaClass;
  const AQuery: array of string; const AJSONArray: TJSONArray; out AObjects: TArray<TBackendEntityValue>);
var
  LObjectIDArray: TArray<TLeanCloudAPI.TObjectID>;
  LUsersArray: TArray<TLeanCloudAPI.TUser>;
  LObjectID: TLeanCloudAPI.TObjectID;
  LList: TList<TBackendEntityValue>;
  LUser: TLeanCloudAPI.TUser;
begin

  if SameText(AClass.BackendDataType, TBackendQueryServiceNames.Storage) then
    LeanCloudAPI.QueryClass(
      AClass.BackendClassName, AQuery, AJSONArray, LObjectIDArray)
  else if SameText(AClass.BackendDataType, TBackendQueryServiceNames.Users) then
    LeanCloudAPI.QueryUsers(
      AQuery, AJSONArray, LUsersArray)
  else if SameText(AClass.BackendDataType, TBackendQueryServiceNames.Installations) then
    LeanCloudAPI.QueryInstallation(
      AQuery, AJSONArray, LObjectIDArray)
  else
    raise EBackendServiceError.CreateFmt(sUnsupportedBackendQueryType, [AClass.BackendDataType]);

  if Length(LUsersArray) > 0 then
  begin
    LList := TList<TBackendEntityValue>.Create;
    try
      for LUser in LUsersArray do
        LList.Add(TLeanCloudMetaFactory.CreateMetaFoundUser(LUser));
      AObjects := LList.ToArray;
    finally
      LList.Free;
    end;
  end;

  if Length(LObjectIDArray) > 0 then
  begin
    LList := TList<TBackendEntityValue>.Create;
    try
      for LObjectID in LObjectIDArray do
        LList.Add(TLeanCloudMetaFactory.CreateMetaClassObject(LObjectID));
      AObjects := LList.ToArray;
    finally
      LList.Free;
    end;
  end;

end;

{ TLeanCloudQueryService }

function TLeanCloudQueryService.CreateQueryApi: IBackendQueryApi;
begin
  Result := CreateBackendApi;
end;

function TLeanCloudQueryService.GetQueryApi: IBackendQueryApi;
begin
  EnsureBackendApi;
  Result := FBackendAPI;
end;

{ TLeanCloudUsersService }

function TLeanCloudUsersService.CreateUsersApi: IBackendUsersApi;
begin
  Result := CreateBackendApi;
end;

function TLeanCloudUsersService.GetUsersApi: IBackendUsersApi;
begin
  EnsureBackendApi;
  Result := FBackendAPI;
end;

{ TLeanCloudLoginService }

function TLeanCloudLoginService.CreateAuthApi: IBackendAuthApi;
begin
  Result := CreateBackendApi;
end;

function TLeanCloudLoginService.GetAuthApi: IBackendAuthApi;
begin
  EnsureBackendApi;
  Result := FBackendAPI;
end;

{ TLeanCloudStorageAPI }

                                              
procedure TLeanCloudStorageAPI.CreateObject(const AClass: TBackendMetaClass;
  const AACL, AJSON: TJSONObject; out ACreatedObject: TBackendEntityValue);
var
  LNewObject: TLeanCloudAPI.TObjectID;
begin
  LeanCloudAPI.CreateClass(AClass.BackendClassName, AACL, AJSON, LNewObject);
  ACreatedObject := TLeanCloudMetaFactory.CreateMetaCreatedObject(LNewObject)
end;

function TLeanCloudStorageAPI.DeleteObject(
  const AObject: TBackendEntityValue): Boolean;
begin
  if AObject.Data is TMetaObject then
    Result := LeanCloudAPI.DeleteClass((AObject.Data as TMetaObject).ObjectID)
  else
    raise EArgumentException.Create(sParameterNotMetaType);
end;

function TLeanCloudStorageAPI.FindObject(const AObject: TBackendEntityValue;
  AProc: TFindObjectProc): Boolean;
var
  LMetaObject: TMetaObject;
begin
  if AObject.Data is TMetaObject then
  begin
    LMetaObject := TMetaObject(AObject.Data);
    Result := LeanCloudAPI.FindClass(LMetaObject.ObjectID,
      procedure(const AID: TLeanCloudAPI.TObjectID; const AObj: TJSONObject)
      begin
        AProc(TLeanCloudMetaFactory.CreateMetaFoundObject(AID), AObj);
      end);
  end
  else
    raise EArgumentException.Create(sParameterNotMetaType);
end;

function TLeanCloudStorageAPI.GetMetaFactory: IBackendMetaFactory;
begin
  Result := TMetaFactory.Create;
end;

procedure TLeanCloudStorageAPI.QueryObjects(const AClass: TBackendMetaClass;
  const AQuery: array of string; const AJSONArray: TJSONArray);
begin
  LeanCloudAPI.QueryClass(AClass.BackendClassName, AQuery, AJSONArray);
end;

procedure TLeanCloudStorageAPI.QueryObjects(const AClass: TBackendMetaClass;
  const AQuery: array of string; const AJSONArray: TJSONArray;
  out AObjects: TArray<TBackendEntityValue>);
var
  LObjectIDArray: TArray<TLeanCloudAPI.TObjectID>;
  LObjectID: TLeanCloudAPI.TObjectID;
  LList: TList<TBackendEntityValue>;
begin
  LeanCloudAPI.QueryClass(AClass.BackendClassName, AQuery, AJSONArray, LObjectIDArray);
  if Length(LObjectIDArray) > 0 then
  begin
    LList := TList<TBackendEntityValue>.Create;
    try
      for LObjectID in LObjectIDArray do
        LList.Add(TLeanCloudMetaFactory.CreateMetaClassObject(LObjectID));
      AObjects := LList.ToArray;
    finally
      LList.Free;
    end;
  end;
end;

procedure TLeanCloudStorageAPI.UpdateObject(const AObject: TBackendEntityValue;
  const AJSONObject: TJSONObject; out AUpdatedObject: TBackendEntityValue);
var
  LObjectID: TLeanCloudAPI.TUpdatedAt;
  LMetaObject: TMetaObject;
begin
  if AObject.Data is TMetaObject then
  begin
    LMetaObject := TMetaObject(AObject.Data);
    LeanCloudAPI.UpdateClass(LMetaObject.ObjectID, AJSONObject, LObjectID);
    AUpdatedObject := TLeanCloudMetaFactory.CreateMetaUpdatedObject(LObjectID);
  end
  else
    raise EArgumentException.Create(sParameterNotMetaType);
end;

{ TLeanCloudStorageService }

function TLeanCloudStorageService.CreateStorageApi: IBackendStorageApi;
begin
  Result := CreateBackendApi;
end;

function TLeanCloudStorageService.GetStorageApi: IBackendStorageApi;
begin
  EnsureBackendApi;
  Result := FBackendAPI;
end;

var
  FFactories: TList<TProviderServiceFactory>;

procedure RegisterServices;
var
  LFactory: TProviderServiceFactory;
begin
  FFactories := TObjectList<TProviderServiceFactory>.Create;
  // Files
  LFactory := TLeanCloudProviderServiceFactory<IBackendFilesService>.Create(
    function(AProvider: IBackendProvider): IBackendService
    begin
      Result := TLeanCloudFilesService.Create(AProvider);
    end);
  FFactories.Add(LFactory);

  // Users
  LFactory := TLeanCloudProviderServiceFactory<IBackendUsersService>.Create(
    function(AProvider: IBackendProvider): IBackendService
    begin
      Result := TLeanCloudUsersService.Create(AProvider);
    end);
  FFactories.Add(LFactory);

  // Login
  LFactory := TLeanCloudProviderServiceFactory<IBackendAuthService>.Create(
    function(AProvider: IBackendProvider): IBackendService
    begin
      Result := TLeanCloudLoginService.Create(AProvider);
    end);
  FFactories.Add(LFactory);

  // Storage
  LFactory := TLeanCloudProviderServiceFactory<IBackendStorageService>.Create(
    function(AProvider: IBackendProvider): IBackendService
    begin
      Result := TLeanCloudStorageService.Create(AProvider);
    end);
  FFactories.Add(LFactory);

  // Query
  LFactory := TLeanCloudProviderServiceFactory<IBackendQueryService>.Create(
    function(AProvider: IBackendProvider): IBackendService
    begin
      Result := TLeanCloudQueryService.Create(AProvider);
    end);
  FFactories.Add(LFactory);

  // Push
  LFactory := TLeanCloudProviderServiceFactory<IBackendPushService>.Create(
    function(AProvider: IBackendProvider): IBackendService
    begin
      Result := TLeanCloudPushService.Create(AProvider);
    end);
  FFactories.Add(LFactory);
  for LFactory in FFactories do
    LFactory.Register;
end;

procedure UnregisterServices;
var
  LFactory: TProviderServiceFactory;
begin
  for LFactory in FFactories do
    LFactory.Unregister;
  FreeAndNil(FFactories);
end;

{ TLeanCloudLoginAPI }

function TLeanCloudLoginAPI.GetMetaFactory: IBackendMetaFactory;
begin
  Result := TMetaFactory.Create;
end;

function TLeanCloudLoginAPI.FindCurrentUser(const AObject: TBackendEntityValue;
  AProc: TFindObjectProc): Boolean;
var
  LMetaLogin: TMetaLogin;
begin
  if AObject.Data is TMetaLogin then
  begin
    LMetaLogin := TMetaLogin(AObject.Data);
    LeanCloudAPI.Login(LMetaLogin.Login);
    try
      Result := LeanCloudAPI.RetrieveCurrentUser(
        procedure(const AUser: TLeanCloudAPI.TUser; const AObj: TJSONObject)
        begin
          AProc(TLeanCloudMetaFactory.CreateMetaFoundUser(AUser), AObj);
        end);
    finally
      LeanCloudAPI.Logout;
    end;
  end
  else
    raise EArgumentException.Create(sParameterNotMetaType);
end;

function TLeanCloudLoginAPI.FindCurrentUser(const AObject: TBackendEntityValue;
  out AUser: TBackendEntityValue; const AJSON: TJSONArray): Boolean;
var
  LMetaLogin: TMetaLogin;
  LUser: TLeanCloudAPI.TUser;
begin
  if AObject.Data is TMetaLogin then
  begin
    LMetaLogin := TMetaLogin(AObject.Data);
    LeanCloudAPI.Login(LMetaLogin.Login);
    try
      Result := LeanCloudAPI.RetrieveCurrentUser(LUser, AJSON);
      AUser := TLeanCloudMetaFactory.CreateMetaFoundUser(LUser);
    finally
      LeanCloudAPI.Logout;
    end;
  end
  else
    raise EArgumentException.Create(sParameterNotMetaType);
end;

procedure TLeanCloudLoginAPI.LoginUser(const AUserName, APassword: string;
  AProc: TFindObjectProc);
begin
  LeanCloudAPI.LoginUser(AUserName, APassword,
   procedure(const ALogin: TLeanCloudAPI.TLogin; const AUserObject: TJSONObject)
   begin
      AProc(TLeanCloudMetaFactory.CreateMetaLoginUser(ALogin), AUserObject);
   end);
end;

procedure TLeanCloudLoginAPI.LoginUser(const AUserName, APassword: string;
  out AUser: TBackendEntityValue; const AJSON: TJSONArray);
var
  LLogin: TLeanCloudAPI.TLogin;
begin
  LeanCloudAPI.LoginUser(AUserName, APassword, LLogin, AJSON);
  AUser := TLeanCloudMetaFactory.CreateMetaLoginUser(LLogin);
end;


procedure TLeanCloudLoginAPI.SignupUser(const AUserName, APassword: string;
  const AUserData: TJSONObject; out ACreatedObject: TBackendEntityValue);
var
  LLogin: TLeanCloudAPI.TLogin;
begin
  LeanCloudAPI.SignupUser(AUserName, APassword, AUserData, LLogin);
  ACreatedObject := TLeanCloudMetaFactory.CreateMetaSignupUser(LLogin);
end;

procedure TLeanCloudLoginAPI.UpdateUser(const AObject: TBackendEntityValue;
  const AUserData: TJSONObject; out AUpdatedObject: TBackendEntityValue);
var
  LUpdated: TLeanCloudAPI.TUpdatedAt;
begin
  if AObject.Data is TMetaLogin then
  begin
    LeanCloudAPI.UpdateUser(TMetaLogin(AObject.Data).Login, AUserData, LUpdated);
    AUpdatedObject := TLeanCloudMetaFactory.CreateMetaUpdatedUser(LUpdated);
  end
  else if AObject.Data is TMetaUser then
  begin
    LeanCloudAPI.UpdateUser(TMetaUser(AObject.Data).User.ObjectID, AUserData, LUpdated);
    AUpdatedObject := TLeanCloudMetaFactory.CreateMetaUpdatedUser(LUpdated);
  end
  else
    raise EArgumentException.Create(sParameterNotMetaType);
end;

{ TLeanCloudUsersAPI }

function TLeanCloudUsersAPI.DeleteUser(const AObject: TBackendEntityValue): Boolean;
begin
  if AObject.Data is TMetaLogin then
    Result := LeanCloudAPI.DeleteUser((AObject.Data as TMetaLogin).Login)
  else if AObject.Data is TMetaUser then
    Result := LeanCloudAPI.DeleteUser((AObject.Data as TMetaUser).User.ObjectID)
  else
    raise EArgumentException.Create(sParameterNotMetaType);
end;

function TLeanCloudUsersAPI.FindUser(const AObject: TBackendEntityValue;
  AProc: TFindObjectProc): Boolean;
begin
  if AObject.Data is TMetaLogin then
  begin
    Result := LeanCloudAPI.RetrieveUser(TMetaLogin(AObject.Data).Login,
      procedure(const AUser: TLeanCloudAPI.TUser; const AObj: TJSONObject)
      begin
        AProc(TLeanCloudMetaFactory.CreateMetaFoundUser(AUser), AObj);
      end);
  end
  else if AObject.Data is TMetaUser then
  begin
    Result := LeanCloudAPI.RetrieveUser(TMetaUser(AObject.Data).User.ObjectID,
      procedure(const AUser: TLeanCloudAPI.TUser; const AObj: TJSONObject)
      begin
        AProc(TLeanCloudMetaFactory.CreateMetaFoundUser(AUser), AObj);
      end);
  end
  else
    raise EArgumentException.Create(sParameterNotMetaType);
end;

function TLeanCloudUsersAPI.FindUser(const AObject: TBackendEntityValue;
  out AUser: TBackendEntityValue; const AJSON: TJSONArray): Boolean;
var
  LUser: TLeanCloudAPI.TUser;
begin
  if AObject.Data is TMetaLogin then
    Result := LeanCloudAPI.RetrieveUser(TMetaLogin(AObject.Data).Login, LUser, AJSON)
  else if AObject.Data is TMetaUser then
    Result := LeanCloudAPI.RetrieveUser(TMetaUser(AObject.Data).User.ObjectID, LUser, AJSON)
  else
    raise EArgumentException.Create(sParameterNotMetaType);

  AUser := TLeanCloudMetaFactory.CreateMetaFoundUser(LUser);
end;


function TLeanCloudUsersAPI.QueryUserName(const AUserName: string;
  AProc: TFindObjectProc): Boolean;
begin
  Result := LeanCloudAPI.QueryUserName(AUserName,
    procedure(const AUser: TLeanCloudAPI.TUser; const AObj: TJSONObject)
    begin
      AProc(TLeanCloudMetaFactory.CreateMetaFoundUser(AUser), AObj);
    end);
end;

function TLeanCloudUsersAPI.QueryUserName(const AUserName: string;
  out AUser: TBackendEntityValue; const AJSON: TJSONArray): Boolean;
var
  LUser: TLeanCloudAPI.TUser;
begin
  Result := LeanCloudAPI.QueryUserName(AUserName, LUser, AJSON);
  AUser := TLeanCloudMetaFactory.CreateMetaFoundUser(LUser);
end;


procedure TLeanCloudUsersAPI.QueryUsers(
  const AQuery: array of string; const AJSONArray: TJSONArray);
begin
  LeanCloudAPI.QueryUsers(
    AQuery, AJSONArray);
end;

procedure TLeanCloudUsersAPI.QueryUsers(
  const AQuery: array of string; const AJSONArray: TJSONArray; out AMetaArray: TArray<TBackendEntityValue>);
var
  LUserArray: TArray<TLeanCloudAPI.TUser>;
  LUser: TLeanCloudAPI.TUser;
  LList: TList<TBackendEntityValue>;
begin
  LeanCloudAPI.QueryUsers(
    AQuery, AJSONArray, LUserArray);
  if Length(LUserArray) > 0 then
  begin
    LList := TList<TBackendEntityValue>.Create;
    try
      for LUser in LUserArray do
        LList.Add(TLeanCloudMetaFactory.CreateMetaFoundUser(LUser));
      AMetaArray := LList.ToArray;
    finally
      LList.Free;
    end;
  end;

end;

procedure TLeanCloudUsersAPI.UpdateUser(const AObject: TBackendEntityValue;
  const AUserData: TJSONObject; out AUpdatedObject: TBackendEntityValue);
var
  LUpdated: TLeanCloudAPI.TUpdatedAt;
begin
  if AObject.Data is TMetaLogin then
  begin
    LeanCloudAPI.UpdateUser(TMetaLogin(AObject.Data).Login, AUserData, LUpdated);
    AUpdatedObject := TLeanCloudMetaFactory.CreateMetaUpdatedUser(LUpdated);
  end
  else if AObject.Data is TMetaUser then
  begin
    LeanCloudAPI.UpdateUser(TMetaUser(AObject.Data).User.ObjectID, AUserData, LUpdated);
    AUpdatedObject := TLeanCloudMetaFactory.CreateMetaUpdatedUser(LUpdated);
  end
  else
    raise EArgumentException.Create(sParameterNotMetaType);
end;

{ TLeanCloudFilesAPI }


procedure TLeanCloudFilesAPI.UploadFile(const AFileName, AContentType: string;
  out AFile: TBackendEntityValue);
var
  LFile: TLeanCloudAPI.TFile;
begin
  // Upload public file
  LeanCloudAPI.UploadFile(AFileName, AContentType,LFile);
  AFile :=  TLeanCloudMetaFactory.CreateMetaUploadedFile(LFile);
end;

function TLeanCloudFilesAPI.DeleteFile(const AFile: TBackendEntityValue): Boolean;
var
  LMetaFile: TMetaFile;
begin
  if AFile.Data is TMetaFile then
  begin
    LMetaFile := TMetaFile(AFile.Data);
    Result := LeanCloudAPI.DeleteFile(LMetaFile.FileValue);
  end
  else
    raise EArgumentException.Create(sParameterNotMetaType);
end;

function TLeanCloudFilesAPI.GetMetaFactory: IBackendMetaFactory;
begin
  Result := TMetaFactory.Create;
end;

procedure TLeanCloudFilesAPI.UploadFile(const AFileName: string;
  const AStream: TStream; const AContentType: string;
  out AFile: TBackendEntityValue);
var
  LFile: TLeanCloudAPI.TFile;
begin
  // Upload public file
  LeanCloudAPI.UploadFile(AFileName, AStream, AContentType, LFile);
  AFile :=  TLeanCloudMetaFactory.CreateMetaUploadedFile(LFile);
end;

initialization
  RegisterServices;
finalization
  UnregisterServices;

end.
