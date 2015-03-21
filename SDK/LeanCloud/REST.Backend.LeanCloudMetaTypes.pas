{*******************************************************}
{                                                       }
{             Delphi REST Client Framework              }
{                                                       }
{ Copyright(c) 2015 yuanpeng                            }
{                                                       }
{*******************************************************}
unit REST.Backend.LeanCloudMetaTypes;

interface

uses
  System.Classes,
  System.SysUtils,
  System.JSON,
  REST.Backend.Providers,
  REST.Backend.MetaTypes,
  REST.Backend.LeanCloudProvider,
  REST.Backend.LeanCloudApi;

type

  // Describe an object
  TMetaObject = class(TInterfacedObject, IBackendMetaObject)
  private
    FObjectID: TLeanCloudAPI.TObjectID;
  protected
    function GetObjectID: string;
    function GetCreatedAt: TDateTime;
    function GetUpdatedAt: TDateTime;
    function GetClassName: string;
  public
    constructor Create(const AObjectID: TLeanCloudAPI.TObjectID);
    property ObjectID: TLeanCloudAPI.TObjectID read FObjectID;
  end;

  // Define MetaObject with ObjectID and CreatedAt properties
  TMetaCreatedObject = class(TMetaObject, IBackendMetaObject,
     IBackendObjectID, IBackendClassName, IBackendCreatedAt)
  end;

  // Define MetaObject with ObjectID and BackendClassName properties
  TMetaClassObject = class(TMetaObject, IBackendMetaObject, IBackendClassName,
     IBackendObjectID)
  end;

  // Define MetaObject with UpdatedAt properties
  TMetaUpdatedObject = class(TInterfacedObject, IBackendMetaObject)
  private
    FUpdatedAt: TLeanCloudAPI.TUpdatedAt;
  protected
    function GetObjectID: string;
    function GetUpdatedAt: TDateTime;
    function GetClassName: string;
  public
    constructor Create(const AUpdatedAt: TLeanCloudAPI.TUpdatedAt);
    property ObjectID: TLeanCloudAPI.TUpdatedAt read FUpdatedAt;
  end;

  // Describe a user object
  TMetaUser = class(TInterfacedObject, IBackendMetaObject)
  private
    FUser: TLeanCloudAPI.TUser;
  protected
    function GetObjectID: string;
    function GetCreatedAt: TDateTime;
    function GetUpdatedAt: TDateTime;
    function GetUserName: string;
  public
    constructor Create(const AUser: TLeanCloudAPI.TUser);
    property User: TLeanCloudAPI.TUser read FUser;
  end;

  // Describe an uploaded file
  TMetaFile = class(TInterfacedObject, IBackendMetaObject)
  private
    FFile: TLeanCloudAPI.TFile;
  protected
    function GetDownloadURL: string;
    function GetFileName: string;
    function GetFileID: string;
  public
    constructor Create(const AFile: TLeanCloudAPI.TFile); overload;
    constructor Create(const AFileID: string); overload;
    property FileValue: TLeanCloudAPI.TFile read FFile;
  end;

  // Define MetaObject with ObjectID and BackendClassName properties
  TMetaUserObject = class(TMetaUser, IBackendMetaObject,
     IBackendObjectID)
  end;

  // Describe an logged in user
  TMetaLogin = class(TMetaUser)
  private
    FLogin: TLeanCloudAPI.TLogin;
  protected
    function GetAuthTOken: string;
  public
    constructor Create(const ALogin: TLeanCloudAPI.TLogin);
    property Login: TLeanCloudAPI.TLogin read FLogin;
  end;

  TMetaFoundObject = class(TMetaObject, IBackendMetaObject, IBackendClassName,
     IBackendObjectID, IBackendCreatedAt, IBackendUpdatedAt)
  end;

  TMetaUploadedFile = class(TMetaFile, IBackendMetaObject, IBackendFileID, IBackendFileName,
     IBackendDownloadURL)
  end;

  TMetaFileObject = class(TMetaFile, IBackendMetaObject, IBackendFileID)
  end;

  // Define MetaObject with UpdatedAt properties
  TMetaUpdatedUser = class(TMetaUser, IBackendMetaObject, IBackendUpdatedAt, IBackendUserName)
  end;

  TMetaFoundUser = class(TMetaUser, IBackendMetaObject,
     IBackendObjectID, IBackendCreatedAt, IBackendUpdatedAt, IBackendUserName)
  end;

  TMetaLoginUser = class(TMetaLogin, IBackendMetaObject,
     IBackendObjectID, IBackendCreatedAt, IBackendUpdatedAt, IBackendUserName, IBackendAuthToken)
  end;

  TMetaSignupUser = class(TMetaLogin, IBackendMetaObject,
     IBackendObjectID, IBackendCreatedAt, IBackendUserName, IBackendAuthToken)
  end;

  // Describe a backend class
  TMetaClass = class(TInterfacedObject, IBackendMetaObject)
  private
    FClassName: string;
    FDataType: string;
  protected
    function GetClassName: string;
    function GetDataType: string;
  public
    constructor Create(const AClassName: string); overload;
    constructor Create(const ADataType, AClassName: string); overload;
  end;

  // Defined backend class with ClassName property
  TMetaClassName = class(TMetaClass, IBackendMetaClass, IBackendClassName)
  end;

  // Defined backend class with ClassName and DataType property
  TMetaDataType = class(TMetaClass, IBackendMetaClass, IBackendClassName, IBackendDataType)
  end;

  TMetaFactory = class(TInterfacedObject, IBackendMetaFactory, IBackendMetaClassFactory,
    IBackendMetaClassObjectFactory, IBackendMetaDataTypeFactory, IBackendMetaFileFactory)
  protected
    { IBackendMetaClassFactory }
    function CreateMetaClass(const AClassName: string): TBackendMetaClass;
    { IBackendMetaClassObjectFactory }
    function CreateMetaClassObject(const AClassName, AObjectID: string): TBackendEntityValue;
    { IBackendMetaDataTypeFactory }
    function CreateMetaDataType(const ADataType, ABackendClassName: string): TBackendMetaClass;
    { IBackendMetaFileFactory }
    function CreateMetaFileObject(const AFileID: string): TBackendEntityValue;
  end;

  TLeanCloudMetaFactory = class
  public
    // Class
    class function CreateMetaClass(const AClassName: string): TBackendMetaClass; static;
    class function CreateMetaDataType(const ADataType, AClassName: string): TBackendMetaClass; overload; static;
    // Object
     class function CreateMetaClassObject(const AClassName, AObjectID: string): TBackendEntityValue; overload;static;
    class function CreateMetaClassObject(const AObjectID: TLeanCloudAPI.TObjectID): TBackendEntityValue; overload;static;
    class function CreateMetaCreatedObject(
      const AObjectID: TLeanCloudAPI.TObjectID): TBackendEntityValue; static;
    class function CreateMetaFoundObject(const AObjectID: TLeanCloudAPI.TObjectID): TBackendEntityValue; static;
    class function CreateMetaUpdatedObject(const AUpdatedAt: TLeanCloudAPI.TUpdatedAt): TBackendEntityValue; static;
   // User
    class function CreateMetaUpdatedUser(const AUpdatedAt: TLeanCloudAPI.TUpdatedAt): TBackendEntityValue; overload; static;
    class function CreateMetaSignupUser(const ALogin: TLeanCloudAPI.TLogin): TBackendEntityValue; overload; static;
    class function CreateMetaLoginUser(const ALogin: TLeanCloudAPI.TLogin): TBackendEntityValue; overload; static;
    class function CreateMetaFoundUser(const AUser: TLeanCloudAPI.TUser): TBackendEntityValue; static;
    // Files
    class function CreateMetaUploadedFile(const AFile: TLeanCloudAPI.TFile): TBackendEntityValue; static;
    class function CreateMetaFileObject(const AFileID: string): TBackendEntityValue;
  end;

implementation

{ TMetaCreatedObject }

constructor TMetaObject.Create(const AObjectID: TLeanCloudAPI.TObjectID);
begin
  inherited Create;
  FObjectID := AObjectID;
end;

function TMetaObject.GetCreatedAt: TDateTime;
begin
  Result := FObjectID.CreatedAt;
end;

function TMetaObject.GetObjectID: string;
begin
  Result := FObjectID.ObjectID;
end;

function TMetaObject.GetUpdatedAt: TDateTime;
begin
  Result := FObjectID.UpdatedAt;
end;

function TMetaObject.GetClassName: string;
begin
  Result := FObjectID.BackendClassName;
end;

{ TMetaClass }

constructor TMetaClass.Create(const AClassName: string);
begin
  inherited Create;
  FClassName := AClassName;
end;

constructor TMetaClass.Create(const ADataType, AClassName: string);
begin
  Create(AClassName);
  FDataType := ADataType;
end;

function TMetaClass.GetClassName: string;
begin
  Result := FClassName;
end;

function TMetaClass.GetDataType: string;
begin
  Result := FDataType;
end;

{ TMetaFactory }

function TMetaFactory.CreateMetaClass(
  const AClassName: string): TBackendMetaClass;
begin
  Result := TLeanCloudMetaFactory.CreateMetaClass(AClassName);
end;

function TMetaFactory.CreateMetaClassObject(
  const AClassName: string; const AObjectID: string): TBackendEntityValue;
begin
  Result := TLeanCloudMetaFactory.CreateMetaClassObject(AClassName, AObjectID);
end;

function TMetaFactory.CreateMetaDataType(const ADataType,
  ABackendClassName: string): TBackendMetaClass;
begin
  Result := TLeanCloudMetaFactory.CreateMetaDataType(ADataType, ABackendClassName);
end;

function TMetaFactory.CreateMetaFileObject(
  const AFileID: string): TBackendEntityValue;
begin
  Result := TLeanCloudMetaFactory.CreateMetaFileObject(AFileID);
end;

{ TLeanCloudMetaFactory }

class function TLeanCloudMetaFactory.CreateMetaClass(
  const AClassName: string): TBackendMetaClass;
var
  LIntf: IBackendMetaClass;
begin
  LIntf := TMetaClassName.Create(AClassName);
  Assert(Supports(LIntf, IBackendClassName));
  Result := TBackendMetaClass.Create(LIntf);
end;

class function TLeanCloudMetaFactory.CreateMetaClassObject(
  const AClassName: string; const AObjectID: string): TBackendEntityValue;
var
  LObjectID: TLeanCloudAPI.TObjectID;
begin
  LObjectID := TLeanCloudAPI.TObjectID.Create(AClassName, AObjectID);
  Result := CreateMetaClassObject(LObjectID);
end;

class function TLeanCloudMetaFactory.CreateMetaClassObject(
  const AObjectID: TLeanCloudAPI.TObjectID): TBackendEntityValue;
var
  LIntf: IBackendMetaObject;
begin
  LIntf := TMetaClassObject.Create(AObjectID);
  Assert(Supports(LIntf, IBackendClassName));
  Assert(Supports(LIntf, IBackendObjectID));
  Result := TBackendEntityValue.Create(LIntf);
end;

class function TLeanCloudMetaFactory.CreateMetaCreatedObject(
  const AObjectID: TLeanCloudAPI.TObjectID): TBackendEntityValue;
var
  LIntf: IBackendMetaObject;
begin
  LIntf := TMetaCreatedObject.Create(AObjectID);
  Result := TBackendEntityValue.Create(LIntf);
end;

class function TLeanCloudMetaFactory.CreateMetaDataType(const ADataType,
  AClassName: string): TBackendMetaClass;
var
  LIntf: IBackendMetaClass;
begin
  LIntf := TMetaDataType.Create(ADataType, AClassName);
  Result := TBackendMetaClass.Create(LIntf);
end;

class function TLeanCloudMetaFactory.CreateMetaFileObject(
  const AFileID: string): TBackendEntityValue;
var
  LIntf: IBackendMetaObject;
begin
  LIntf := TMetaFileObject.Create(AFileID);
  Result := TBackendEntityValue.Create(LIntf);
end;

class function TLeanCloudMetaFactory.CreateMetaFoundObject(
  const AObjectID: TLeanCloudAPI.TObjectID): TBackendEntityValue;
var
  LIntf: IBackendMetaObject;
begin
  LIntf := TMetaFoundObject.Create(AObjectID);
  Result := TBackendEntityValue.Create(LIntf);
end;

class function TLeanCloudMetaFactory.CreateMetaFoundUser(
  const AUser: TLeanCloudAPI.TUser): TBackendEntityValue;
var
  LIntf: IBackendMetaObject;
begin
  LIntf := TMetaFoundUser.Create(AUser);
  Result := TBackendEntityValue.Create(LIntf);
end;

class function TLeanCloudMetaFactory.CreateMetaLoginUser(
  const ALogin: TLeanCloudAPI.TLogin): TBackendEntityValue;
var
  LIntf: IBackendMetaObject;
begin
  LIntf := TMetaLoginUser.Create(ALogin);
  Result := TBackendEntityValue.Create(LIntf);
end;

class function TLeanCloudMetaFactory.CreateMetaSignupUser(
  const ALogin: TLeanCloudAPI.TLogin): TBackendEntityValue;
var
  LIntf: IBackendMetaObject;
begin
  LIntf := TMetaSignupUser.Create(ALogin);
  Result := TBackendEntityValue.Create(LIntf);
end;

class function TLeanCloudMetaFactory.CreateMetaUpdatedObject(
  const AUpdatedAt: TLeanCloudAPI.TUpdatedAt): TBackendEntityValue;
var
  LIntf: IBackendMetaObject;
begin
  LIntf := TMetaUpdatedObject.Create(AUpdatedAt);
  Result := TBackendEntityValue.Create(LIntf);
end;

class function TLeanCloudMetaFactory.CreateMetaUpdatedUser(
  const AUpdatedAt: TLeanCloudAPI.TUpdatedAt): TBackendEntityValue;
var
  LIntf: IBackendMetaObject;
begin
  LIntf := TMetaUpdatedObject.Create(AUpdatedAt);
  Result := TBackendEntityValue.Create(LIntf);
end;

class function TLeanCloudMetaFactory.CreateMetaUploadedFile(
  const AFile: TLeanCloudAPI.TFile): TBackendEntityValue;
var
  LIntf: IBackendMetaObject;
begin
  LIntf := TMetaUploadedFile.Create(AFile);
  Result := TBackendEntityValue.Create(LIntf);
end;

{ TMetaUpdateObject }

constructor TMetaUpdatedObject.Create(const AUpdatedAt: TLeanCloudAPI.TUpdatedAt);
begin
  FUpdatedAt := AUpdatedAt;
end;

function TMetaUpdatedObject.GetClassName: string;
begin
  Result := FUpdatedAt.BackendClassName;
end;

function TMetaUpdatedObject.GetObjectID: string;
begin
  Result := FUpdatedAt.ObjectID;
end;

function TMetaUpdatedObject.GetUpdatedAt: TDateTime;
begin
  Result := FUpdatedAt.UpdatedAt;
end;

{ TMetaUser }

constructor TMetaUser.Create(const AUser: TLeanCloudAPI.TUser);
begin
  FUser := AUser;
end;

function TMetaUser.GetCreatedAt: TDateTime;
begin
  Result := FUser.CreatedAt;
end;

function TMetaUser.GetObjectID: string;
begin
  Result := FUser.ObjectID;
end;

function TMetaUser.GetUpdatedAt: TDateTime;
begin
  Result := FUser.UpdatedAt;
end;

function TMetaUser.GetUserName: string;
begin
  Result := FUser.UserName;
end;

{ TMetaLogin }

constructor TMetaLogin.Create(const ALogin: TLeanCloudAPI.TLogin);
begin
  inherited Create(ALogin.User);
  FLogin := ALogin;
end;

function TMetaLogin.GetAuthTOken: string;
begin
  Result := FLogin.SessionToken;
end;

{ TMetaFile }

constructor TMetaFile.Create(const AFile: TLeanCloudAPI.TFile);
begin
  FFile := AFile;
end;

function TMetaFile.GetFileID: string;
begin
  Result := FFile.Name;
end;

function TMetaFile.GetFileName: string;
begin
  Result := FFile.FileName;
end;

constructor TMetaFile.Create(const AFileID: string);
begin
  FFile := TLeanCloudAPI.TFile.Create(AFileID);
end;

function TMetaFile.GetDownloadURL: string;
begin
  Result := FFile.DownloadURL;
end;

end.
