unit UnBaaSDemo;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, IPPeerClient, REST.Backend.ServiceTypes, REST.Backend.MetaTypes, System.JSON,
  REST.Backend.LeanCloudServices, REST.Backend.Providers, REST.Backend.ServiceComponents, Data.Bind.Components,
  Data.Bind.ObjectScope, REST.Backend.BindSource, REST.Backend.LeanCloudProvider, Vcl.ComCtrls, Vcl.StdCtrls,
  qjson, //引用sdk\qsjon\source
  DateUtils, //日期函数
  VCLTee.TeCanvas, VCLTee.TeeEdiGrad, Vcl.ExtCtrls, Vcl.Imaging.jpeg;

type
  TForm3 = class(TForm)
    Panel1: TPanel;
    Button6: TButton;
    Button3: TButton;
    Button7: TButton;
    Button1: TButton;
    Button8: TButton;
    Button9: TButton;
    Button10: TButton;
    Button11: TButton;
    Memo2: TMemo;
    StatusBar1: TStatusBar;
    LeanCloudProvider1: TLeanCloudProvider;
    BackendStorage1: TBackendStorage;
    BackendUsers1: TBackendUsers;
    BackendQuery1: TBackendQuery;
    BackendFiles1: TBackendFiles;
    Image1: TImage;
    procedure Button6Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button11Click(Sender: TObject);
    procedure Button10Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
  private
    ALogin: TBackendEntityValue;
    Objectid, ObjectName: string;
  public

  end;

var
  Form3: TForm3;

//获得UTC时间字符串
function GetUTCTime: string;

implementation

{$R *.dfm}

function GetUTCTime: string;
var
  pTime: _TIME_ZONE_INFORMATION;
  TimeNow: TDateTime;
  Bias:Longint;
  ss: string;
begin
  GetTimeZoneInformation(pTime);//获取时区
  Bias := pTime.Bias;
  TimeNow := IncMinute(Now, Bias);
  result := DateToISO8601(TimeNow, True);
end;

procedure TForm3.Button10Click(Sender: TObject);
var
  LUpdatedAt: TBackendEntityValue;
var
  LJSON: TJSONObject;
begin
  if BackendUsers1.Users.Authentication <> TBackendAuthentication.Session then
  begin
    ShowMessage('Not logged in');
    exit;
  end;

  LJSON := TJSONObject.Create;
  try
    LJSON.AddPair('password', '888888'); //此处为修改后的密码
    BackendUsers1.Users.UpdateUser(ALogin, LJSON, LUpdatedAt);
  finally
    LJSON.Free;
  end;

  if Memo2.Lines.Count > 20 then
    Memo2.Lines.Clear;
  Memo2.Lines.Add('The password has been changed');

end;

procedure TForm3.Button11Click(Sender: TObject);
begin
  BackendUsers1.Users.Logout;
  if Memo2.Lines.Count > 20 then
    Memo2.Lines.Clear;
  Memo2.Lines.Add('The Account has logout');
end;

procedure TForm3.Button1Click(Sender: TObject);
var
  LStream: TStream;
  LFile: TBackendEntityValue;
  function SaveImage: TStream;
  begin
    Result := TMemoryStream.Create;
    try
      Image1.Picture.Graphic.SaveToStream(Result);
    except
      Result.Free;
      raise;
    end;
  end;
begin
  LStream := SaveImage;
  try
    //文件上传后，存储在LeanCloud的_File表中
    BackendFiles1.Files.UploadFile('splash.png', LStream, 'image/png', LFile);
    if Memo2.Lines.Count > 20 then
      Memo2.Lines.Clear;
    Memo2.Lines.Add('The Image has been uploaded');
  finally
    LStream.Free;
  end;
end;

procedure TForm3.Button3Click(Sender: TObject);
var
  LJSON: TJSONObject;
begin
  LJSON := TJSONObject.Create;
  try
    LJSON.AddPair('email', '12345@qq.com'); //后台_User表
    BackEndUsers1.Users.SignupUser('13812345678', '888888', LJSON, ALogin);
  finally
    LJSON.Free;
  end;

  if Memo2.Lines.Count > 20 then
    Memo2.Lines.Clear;
  Memo2.Lines.Add('The Account has created, AuthToken:' + ALogin.AuthToken);
end;

procedure TForm3.Button6Click(Sender: TObject);
var
  i: integer;
  FValue: TQJson;
begin
  // 其他更多的使用方法参考 https://leancloud.cn/docs/rest_api.html

  BackendQuery1.BackendClassName := 'books'; //LeanCloud后台的一个表名称，注意大小写敏感
  BackendQuery1.QueryLines.Clear;
  BackendQuery1.QueryLines.Add('order=fid,fname'); //排序
  BackendQuery1.QueryLines.Add('keys=fid,fname'); //获取的字段
  BackendQuery1.QueryLines.Add('where={"fid":' + inttostr(1) + '}'); //查询条件
  BackendQuery1.Execute;
  Memo2.Text := BackendQuery1.JSONResult.ToString;
  FValue := TQJson.Create;
  FValue.Value := Memo2.Text;
  for i := 0 to FValue.Count - 1 do
  begin
    Memo2.Lines.Add(FValue.Items[i].ItemByName('fname').AsString + ' ' +
      FValue.Items[i].ItemByName('objectId').AsString); //唯一标识符，注意大小写敏感
    ObjectName := FValue.Items[i].ItemByName('fname').AsString;
    Objectid := FValue.Items[i].ItemByName('objectId').AsString;
  end;
  FValue.Free;
end;

procedure TForm3.Button7Click(Sender: TObject);
begin
  BackendUsers1.Users.LoginUser('13812345678', '888888', ALogin); //验证用户和密码

  if ALogin.AuthToken.IsEmpty() then
  begin
    ShowMessage('no auth token');
    exit;
  end;
  BackendUsers1.Users.Login(ALogin);

  if BackendUsers1.Users.Authentication <> TBackendAuthentication.Session then
  begin
    ShowMessage('Not logged in');
    exit;
  end;

  if Memo2.Lines.Count > 20 then
    Memo2.Lines.Clear;
  Memo2.Lines.Add('The Account has login, AuthToken:' + ALogin.AuthToken);
end;

procedure TForm3.Button8Click(Sender: TObject);
var
  LJSON : TJSONObject;
  ACreatedObject: TBackendEntityValue;
  FValue	: string;
  FDate: TJSONObject;
begin
  LJSON := TJSONObject.Create;
  FDate := TJSONObject.Create;
  if InputQuery('增加', '输入书的名称', FValue) then
  begin
    FDate.AddPair('__type', 'Date');
    FDate.AddPair('iso', GetUTCTime); //时间格式比较特殊，需要做utc处理

    LJSON.AddPair('fid', TJSONNumber.Create(1)); //书本编号，都默认为1
    LJSON.AddPair('fname', FValue); //书的名称
    LJSON.AddPair('fdate', FDate); //日期用fdate做一个json格式处理

    BackendStorage1.Storage.CreateObject('books', LJSON, ACreatedObject);
    Objectid := ACreatedObject.ObjectID;
    ObjectName := FValue;

    if Memo2.Lines.Count > 20 then
      Memo2.Lines.Clear;
    Memo2.Lines.Add('The books has append');
  end;
end;

procedure TForm3.Button9Click(Sender: TObject);
var
  LJSON : TJSONObject;
  ACreatedObject: TBackendEntityValue;
  FValue	: string;
  FDate: TJSONObject;
begin
  if Objectid = '' then
  begin
    Application.MessageBox('请查询数据或增加新记录后再进行当前操作。', '系统提示', MB_OK + MB_ICONINFORMATION);
    exit;
  end;

  LJSON := TJSONObject.Create;
  FDate := TJSONObject.Create;

  if InputQuery('修改' + ObjectName, '输入新的书本名称', FValue) then
  begin
    FDate.AddPair('__type', 'Date');
    FDate.AddPair('iso', GetUTCTime);

    LJSON.AddPair('fname', FValue);
    LJSON.AddPair('fdate', FDate);

    BackendStorage1.Storage.UpdateObject('books', Objectid, LJSON, ACreatedObject); //object是leancloud后台，对表books每条记录自动生成的唯一主键

    if Memo2.Lines.Count > 20 then
      Memo2.Lines.Clear;
    Memo2.Lines.Add('The books has change name');
  end;

end;

procedure TForm3.FormCreate(Sender: TObject);
begin
  //请不要修改以下用户的密码以影响其他朋友的demo效果，谢谢！
  //LeanCloud.cn
  //用户: delphisdk@163.com
  //密码: Delphisdk2015 （首字母大写）

  //win32运行需要libeay32.dll,ssleay32.dll放到exe目录
  //ios运行需要libcrypto.a,libssl.a放到工程文件dpr目录

  LeanCloudProvider1.ApplicationID := '3gfyrh2hkzz6xs42mw2isx32gy8i995t94es3w46xictbvxs';
  LeanCloudProvider1.MasterKey := 'jcb9ndxlprp7w9zpsrllb228ce49q3a7zfbgvm4xu3549lp1';
  LeanCloudProvider1.RestApiKey := '17hd1pyw6r8t6nu972vkgu2t5wm1olrezu3lwjv4ycwkeh4y';
end;

end.
