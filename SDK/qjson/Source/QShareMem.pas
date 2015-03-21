unit QShareMem;

interface

uses classes, sysutils, windows, syncobjs, qstring, qrbtree {$IFDEF UNICODE},
  Generics.Collections{$ENDIF};

type
  TQShareMemoryClient = class;
  TQShareMemoryServer = class;
  TQShareMemoryAddr = Cardinal;

  TQShareHeader = packed record
    SourceProcessId: Cardinal;
    Size: Word;
  end;

  TQShareMemoryStream = class(TCustomMemoryStream)
  protected
    FHandle: THandle;
    FNotify: TEvent;
    constructor Create; override; overload;
  public
    constructor Create(const AName: QStringW; ASize: Integer); overload;
    destructor Destory; override;
    procedure SetSize(NewSize: Longint); override;
  end;

  TQShareMemoryBase = class
  protected
    FReadEvent, FWriteEvent: TEvent;
    FBlockSize: Word;
    FName: QStringW;
    FActive: Boolean;
    FRemoteAddr: TQShareMemoryAddr;
    FLocalAddr: TQShareMemoryAddr;
    procedure SetActive(const Value: Boolean);
  public
    constructor Create(const AName: QStringW; ABlockSize: Word); virtual;
    destructor Destroy; override;
    procedure Open; virtual;
    procedure Close; virtual;
    property Active: Boolean read FActive write SetActive;
    property LocalAddr: TQShareMemoryAddr read FLocalAddr;
    property RemoteAddr: TQShareMemoryAddr read FRemoteAddr;
  end;

  TQNamedPipeServerNotifyEvent = procedure(ASender: TQShareMemoryServer;
    AClient: TQShareMemoryClient);

  TQShareMemoryServer = class(TQShareMemoryBase)
  private
    FAfterClientDisconnect: TQNamedPipeServerNotifyEvent;
    FAfterAccept: TQNamedPipeServerNotifyEvent;
  protected
    FClients: TQRBTree;
  public
    constructor Create(const AName: QStringW; ABlockSize: Word); override;
    destructor Destroy; override;
  published
    property AfterAccept: TQNamedPipeServerNotifyEvent read FAfterAccept
      write FAfterAccept;
    property AfterClientDisconnect: TQNamedPipeServerNotifyEvent
      read FAfterClientDisconnect write FAfterClientDisconnect;
  end;

  TQShareMemoryClient = class
  protected
    FServer: TQShareMemoryServer;
  public
    constructor Create(const AName: QStringW; ABlockSize: Word); override;
    destructor Destroy; override;
    function Write(const ABuf: Pointer; ASize: Integer): Integer;
    function Read(ABuf: Pointer; ASize: Integer): Integer;
    procedure WriteBuffer(const ABuf: Pointer; ASize: Integer);
    procedure ReadBuffer(ABuf: Pointer; ASize: Integer);
  end;

implementation

{ TQShareMemoryStream }

constructor TQShareMemoryStream.Create;
begin
inherited Create;
end;

constructor TQShareMemoryStream.Create(const AName: QStringW; ASize: Integer);
var
  sa: TSecurityAttributes;
  sd: TSecurityDescriptor;
  dwAccess: DWORD;
  e: Integer;
begin
inherited Create;
FNotify := TEvent.Create(nil, false, true, AName + '.Notify');
sa.nLength := sizeOf(TSecurityAttributes);
sa.lpSecurityDescriptor := @sd;
sa.bInheritHandle := false;
InitializeSecurityDescriptor(@sd, SECURITY_DESCRIPTOR_REVISION);
SetSecurityDescriptorDacl(@sd, true, nil, false);
FHandle := CreateFileMappingW(INVALID_HANDLE_VALUE, @sa, PAGE_READWRITE, 0,
  ASize, PQCharW(AName));
if FHandle = 0 then
  RaiseLastOSError(GetLastError);
SetPointer(MapViewOfFile(FHandle, FILE_MAP_WRITE, 0, 0, ASize), ASize);
end;

destructor TQShareMemoryStream.Destory;
begin

inherited;
end;

procedure TQShareMemoryStream.SetSize(NewSize: Integer);
begin
inherited;

end;

end.
