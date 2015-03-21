unit qdb;

interface

{$I 'qdac.inc'}

{ dbcommon实现了表达式过滤
}
uses classes, sysutils, qstring, qrbtree, qworker, db, fmtbcd, dbcommon,
  SqlTimSt, variants, syncobjs, dateutils, qtimetypes, QJson
{$IFDEF UNICODE}
    , Generics.Collections
{$ENDIF}
{$IF RTLVersion<22}// 2007-2010
    , PerlRegEx, pcre
{$ELSE}
    , RegularExpressionsCore
{$IFEND}
    ;

const
  // 数据库架构对象定义
  SCHEMA_DATABASE = $80000000; // 数据库
  SCHEMA_SCHEMA = $40000000; // 元数据定义
  SCHEMA_TABLE = $20000000; // 数据表
  SCHEMA_COLUMN = $10000000; // 数据列
  SCHEMA_TYPE = $08000000; // 数据类型
  SCHEMA_METATYPE = $FF000000; // 元数据类型
  // 数据列属性定义
  SCHEMA_ISINDEX = $00000001; // 索引
  SCHEMA_ISPRIMARY = $00000002; // 主键
  SCHEMA_NULLABLE = $000000004; // 允许为空
  SCHEMA_ISFIXED = $00000008; // 固定长度
  SCHEMA_AUTOINC = $00000010; // 自动增加
  SCHEMA_VISIBLE = $00000020; // 列是否可见
  SCHEMA_READONLY = $00000040; // 列是否只读
  SCHEMA_UNNAMED = $00000080; // 未命名列
  SCHEMA_CALC = $00000100; // 内部计算列
  SCHEMA_ARRAY = $00000200; // 数组类型
  SCHEMA_INWHERE = $00000400; // 可在Where条件中使用，用于更新或删除数据
  SCHEMA_UNIQUE = $00000800; // 唯一约束
  SCHEMA_COLUMNATTR = $000001FF; // 列属性掩码

  // SQL数据类型(32位整数代表数据类型,高16位为掩码，低16位为类型编码)
  SQL_MASK_COMPLEX = $80000000;
  SQL_MASK_NUMERIC = $40000000; // 数值类型ID的掩码
  SQL_MASK_FIXEDSIZE = $20000000; // 固定大小
  SQL_MASK_INTEGER = SQL_MASK_NUMERIC OR SQL_MASK_FIXEDSIZE OR $10000000;
  // 是一个整数类型
  SQL_MASK_UNSIGNED = SQL_MASK_INTEGER OR $08000000; // 无符号类型
  SQL_MASK_FLOAT = SQL_MASK_NUMERIC OR SQL_MASK_FIXEDSIZE; // 浮点数
  SQL_MASK_SPEC = $04000000; // 是特定数据特有类型，如PostgreSQL的特定类型
  SQL_MASK_ARRAY = $02000000; // 是数组的一部分
  SQL_MASK_BINARY = $01000000; // 是二进制数据类型
  SQL_MASK_AUTOINC = SQL_MASK_INTEGER OR $00800000; // 是自增的序列
  SQL_MASK_CHAR = $00400000; // 字符
  SQL_MASK_TIME = SQL_MASK_FIXEDSIZE OR $00200000; // 日期时间类型
  SQL_MASK_LONGSIZE = $00100000; // 长长度类型

  // 字符
  SQL_BASE_CHAR = $00000001; // ANSI字符
  SQL_BASE_WIDECHAR = $00000002; // Unicode字符
  // 整数
  SQL_BASE_BYTE = $00000003; // 单字节
  SQL_BASE_WORD = $00000004; // 双字节
  SQL_BASE_DWORD = $00000005; // 四字节
  SQL_BASE_QWORD = $00000006; // 八字节

  // 浮点数
  SQL_BASE_SINGLE = $00000007; // 单精度浮点值
  SQL_BASE_DOUBLE = $00000008; // 双精度浮点值
  SQL_BASE_EXTENDED = $00000009; // 扩展浮点类型
  SQL_BASE_BCD = $0000000A; // BCD类型
  SQL_BASE_SMALLMONEY = $0000000B; // 短货币
  SQL_BASE_MONEY = $0000000C; // 长货币

  SQL_BASE_BOOLEAN = $0000000D; // 布尔
  SQL_BASE_UUID = $0000000E; // UUID类型
  SQL_BASE_BIT = $0000000F; // 位类型

  // 日期时间
  SQL_BASE_TIME = $00000010; // 时间类型
  SQL_BASE_DATE = $00000011; // 日期类型
  SQL_BASE_SMALLDATETIME = $00000012; // 短日期时间类型
  SQL_BASE_DATETIME = $00000013; // 日期时间类型
  SQL_BASE_INTERVAL = $00000014; // 时间间隔
  SQL_BASE_TIMEOFFSET = $00000015; // 时间偏移
  SQL_BASE_TIMESTAMP = $00000016; // 时间戳

  SQL_BASE_BINARY = $00000017; // 二进制
  // 扩展的类型
  SQL_BASE_PICTURE = $00000018; // 图片（好吧，这个实际上仅早期的少数数据库支持，实际不会用到）
  SQL_BASE_STREAM = $00000019; // 数据流
  SQL_BASE_XML = $0000001A; // XML数据
  SQL_BASE_JSON = $0000001B; // JSON数据

  SQL_BASE_OID = $0000001C; // OID
  SQL_BASE_POINT = $0000001D; // 点
  SQL_BASE_LINE = $0000001E; // 线
  SQL_BASE_LSEG = $0000001F; // 线段
  SQL_BASE_BOX = $00000020; // 矩形
  SQL_BASE_PATH = $00000021; // 路径
  SQL_BASE_POLYGON = $00000022; // 多边形
  SQL_BASE_CIRCLE = $00000023; // 圆
  SQL_BASE_CIDR = $00000024; // 可以带掩码IP地址
  SQL_BASE_INET = $00000025; // IP
  SQL_BASE_MACADDR = $00000026; // 网卡物理地址
  SQL_BASE_ROWS = $00000027; // 行集(记录集)
  SQL_BASE_ACL = $00000028; // 访问控制列表
  SQL_BASE_DATASET = $00000029; // 数据集
  SQL_BASE_CURSOR = $0000002A; // 游标
  SQL_BASE_VARIANT = $0000002B; // 变体
  SQL_BASE_INTERFACE = $0000002C; // 接口
  SQL_BASE_IDISPATCH = $0000002D; // IDispatch
  SQL_BASE_OBJECT = $0000002E; // 对象
  SQL_BASE_PARAMS = $0000002F; // 参数
  SQL_BASE_CONNECTION = $00000030; // 连接
  SQL_BASE_OLE = $00000031; // OLE对象，用OLESave和OLELoad保存和加载
  SQL_BASE_POINTER = $00000032; // 指针引用
  SQL_BASE_ENUM = $00000033; // 枚举
  SQL_BASE_SET = $00000034; // 集合
  SQL_BASE_TSVECTOR = $00000035; // 全文检索向量
  SQL_BASE_TSQUERY = $00000036; // 全文检索查询
  SQL_BASE_ADT = $00000027; // 高级数据类型，用户在服务器端定义的数据类型
  // 基本类型

  SQL_UNKNOWN = $00000000; // 未知类型

  // 整数类型
  SQL_TINYINT = SQL_MASK_INTEGER OR SQL_BASE_BYTE; // -128-127
  SQL_BYTE = SQL_TINYINT OR SQL_MASK_UNSIGNED; // 0-255
  SQL_SMALLINT = SQL_MASK_INTEGER OR SQL_BASE_WORD; // 有符号的-32768-32767
  SQL_WORD = SQL_SMALLINT OR SQL_MASK_UNSIGNED; // 无符号整数，0-65535
  SQL_INTEGER = SQL_MASK_INTEGER OR SQL_BASE_DWORD; // 有符号的32位整数
  SQL_DWORD = SQL_INTEGER OR SQL_MASK_UNSIGNED; // 无符号的32位整数
  SQL_INT64 = SQL_MASK_INTEGER OR SQL_BASE_QWORD; // 有符号的64位整数
  SQL_QWORD = SQL_INT64 OR SQL_MASK_UNSIGNED; // 无符号的64位整数
  SQL_SMALLSERIAL = SQL_SMALLINT OR SQL_MASK_AUTOINC; // 16位自增
  SQL_SERIAL = SQL_INTEGER OR SQL_MASK_AUTOINC; // 32位自增序列
  SQL_BIGSERIAL = SQL_INT64 OR SQL_MASK_AUTOINC; // 64位自增序列

  // 浮点类型
  SQL_SINGLE = SQL_MASK_FLOAT OR SQL_BASE_DWORD OR SQL_BASE_SINGLE; // 有符号的32位实数
  SQL_FLOAT = SQL_MASK_FLOAT OR SQL_BASE_QWORD OR SQL_BASE_DOUBLE; // 有符号的64位实数
  SQL_BCD = SQL_MASK_FLOAT OR SQL_BASE_BCD; // 有符号的任意精度实数
  SQL_NUMERIC = SQL_BCD;
  SQL_MONEY = SQL_MASK_FLOAT OR SQL_BASE_MONEY; // 货币类型
  SQL_SMALLMONEY = SQL_MASK_FLOAT OR SQL_BASE_SMALLMONEY; // 小货币类型
  SQL_EXTENDED = SQL_MASK_FLOAT OR SQL_BASE_EXTENDED;

  // 字符串类型
  SQL_CHAR = SQL_MASK_FIXEDSIZE OR SQL_MASK_CHAR OR SQL_BASE_CHAR; // 固定长度字符串
  SQL_VARCHAR = SQL_MASK_CHAR OR SQL_BASE_CHAR; // 变长字符串
  SQL_WIDECHAR = SQL_MASK_FIXEDSIZE OR SQL_MASK_CHAR OR SQL_BASE_WIDECHAR;
  // 固定长度Unicode字符串
  SQL_WIDEVARCHAR = SQL_MASK_CHAR OR SQL_BASE_WIDECHAR; // 变长Unicode字符串
  SQL_TEXT = SQL_VARCHAR OR SQL_MASK_LONGSIZE; // 文本
  SQL_WIDETEXT = SQL_WIDEVARCHAR OR SQL_MASK_LONGSIZE; // Unicode文本
  SQL_XML = SQL_WIDETEXT OR SQL_BASE_XML;
  SQL_JSON = SQL_WIDETEXT OR SQL_BASE_JSON;

  // 二进制数据类型
  SQL_BINARY = SQL_MASK_FIXEDSIZE OR SQL_MASK_BINARY;
  // 二进制数据
  SQL_BYTES = SQL_BINARY or SQL_BASE_BINARY;
  SQL_BIT = SQL_MASK_FIXEDSIZE OR SQL_BASE_BIT OR SQL_MASK_BINARY;
  SQL_VARBIT = SQL_BASE_BIT OR SQL_MASK_BINARY;
  SQL_VARBINARY = SQL_MASK_BINARY or SQL_BASE_BINARY; // 变长二进制数据
  SQL_VARBYTES = SQL_VARBINARY;
  SQL_LARGEOBJECT = SQL_VARBINARY OR SQL_MASK_LONGSIZE; // 大二进制对象(BLOB)
  SQL_PICTURE = SQL_LARGEOBJECT OR SQL_BASE_PICTURE; // 图片数据
  SQL_STREAM = SQL_LARGEOBJECT OR SQL_BASE_STREAM; // 流对象
  SQL_OLE = SQL_LARGEOBJECT OR SQL_BASE_OLE;

  SQL_BOOLEAN = SQL_MASK_FIXEDSIZE OR SQL_BASE_BOOLEAN; // 布尔
  SQL_UUID = SQL_MASK_FIXEDSIZE OR SQL_BASE_UUID;
  SQL_GUID = SQL_UUID;
  SQL_BITS = SQL_MASK_FIXEDSIZE OR SQL_BASE_BIT;
  SQL_VARBITS = SQL_BASE_BIT;

  // 日期时间类型
  SQL_DATE = SQL_MASK_TIME OR SQL_BASE_DATE; // 日期
  SQL_TIME = SQL_MASK_TIME OR SQL_BASE_TIME; // 时间
  SQL_SMALLDATETIME = SQL_MASK_TIME or SQL_BASE_SMALLDATETIME; // 小日期时间类型
  SQL_DATETIME = SQL_MASK_TIME OR SQL_BASE_DATETIME; // 日期时间
  SQL_TIMESTAMP = SQL_MASK_TIME OR SQL_BASE_TIMESTAMP; // 时间戳
  SQL_INTERVAL = SQL_MASK_TIME OR SQL_BASE_INTERVAL; // 时间间隔
  SQL_TIMEOFFSET = SQL_MASK_TIME OR SQL_BASE_TIMEOFFSET; // 时间偏移

  SQL_DATASET = SQL_MASK_COMPLEX OR SQL_BASE_DATASET; // 数据集
  SQL_CURSOR = SQL_MASK_COMPLEX OR SQL_BASE_CURSOR; // 游标
  SQL_VARIANT = SQL_MASK_COMPLEX OR SQL_BASE_VARIANT; // 变体
  SQL_INTERFACE = SQL_MASK_COMPLEX OR SQL_BASE_INTERFACE; // 接口
  SQL_IDISPATCH = SQL_MASK_COMPLEX OR SQL_BASE_IDISPATCH; // IDispatch
  SQL_OBJECT = SQL_MASK_COMPLEX OR SQL_BASE_OBJECT; // 对象
  SQL_PARAMS = SQL_MASK_COMPLEX OR SQL_BASE_PARAMS; // 参数
  SQL_CONNECTION = SQL_MASK_COMPLEX OR SQL_BASE_CONNECTION; // 连接
  SQL_REFERENCE = SQL_MASK_COMPLEX OR SQL_BASE_POINTER; // 指针引用，这种类型仅在运行时有效
  SQL_ARRAY = SQL_MASK_COMPLEX OR SQL_MASK_ARRAY; // 数组
  SQL_ADT = SQL_MASK_COMPLEX OR SQL_MASK_ARRAY OR SQL_BASE_ADT; // 高级数据类型

  // PostgreSQL类型
  SQL_PG_OID = SQL_MASK_SPEC OR SQL_DWORD OR SQL_MASK_AUTOINC OR SQL_BASE_OID;
  SQL_PG_POINT = SQL_MASK_SPEC OR SQL_MASK_COMPLEX OR SQL_BASE_POINT;
  SQL_PG_LINE = SQL_MASK_SPEC OR SQL_MASK_COMPLEX OR SQL_BASE_LINE;
  SQL_PG_LSEG = SQL_MASK_SPEC OR SQL_MASK_COMPLEX OR SQL_BASE_LSEG;
  SQL_PG_BOX = SQL_MASK_SPEC OR SQL_MASK_COMPLEX OR SQL_BASE_BOX;
  SQL_PG_PATH = SQL_MASK_SPEC OR SQL_MASK_COMPLEX OR SQL_BASE_PATH;
  SQL_PG_POLYGON = SQL_MASK_SPEC OR SQL_MASK_COMPLEX OR SQL_BASE_POLYGON;
  SQL_PG_CIRCLE = SQL_MASK_SPEC OR SQL_MASK_COMPLEX OR SQL_BASE_CIRCLE;
  SQL_PG_CIDR = SQL_MASK_SPEC OR SQL_MASK_COMPLEX OR SQL_BASE_CIDR;
  SQL_PG_INET = SQL_MASK_SPEC OR SQL_MASK_COMPLEX OR SQL_BASE_INET;
  SQL_PG_MACADDR = SQL_MASK_SPEC OR SQL_MASK_COMPLEX OR SQL_BASE_MACADDR;
  SQL_PG_ROWS = SQL_MASK_SPEC OR SQL_MASK_COMPLEX OR SQL_BASE_ROWS;
  SQL_PG_ACL = SQL_MASK_SPEC OR SQL_MASK_COMPLEX OR SQL_BASE_ACL;
  SQL_PG_ENUM = SQL_MASK_SPEC OR SQL_MASK_COMPLEX OR SQL_BASE_ENUM;
  SQL_PG_TSVECTOR = SQL_MASK_SPEC OR SQL_MASK_COMPLEX OR SQL_MASK_CHAR OR
    SQL_BASE_TSVECTOR;
  SQL_PG_TSQUERY = SQL_MASK_SPEC OR SQL_MASK_COMPLEX OR SQL_MASK_CHAR OR
    SQL_BASE_TSQUERY;

  // 已知错误代码
  PROV_ERROR_SQL_EMPTY = $80000001; // 脚本为空
  PROV_EEROR_RESULT_EMPTY = $80000002; // 结果集为空
  PROV_DRIVER_NOT_FOUND = $80000003; // 驱动程序对应的动态链接库未找到
  PROV_NOT_CONNECTED = $80000004; // 连接未就绪
  // Provider标志位
  PF_CONNECTING = $00000001; // 正在连接数据库
  PF_CONNECTED = $00000002; // 已经连接到数据库
  PF_CLOSING = $00000004; // 正在关闭连接
  PF_CLOSED = $00000008; // 连接已经关闭
  PF_EXECUTING = $00000010; // 连接正在执行脚本
  PF_KEEPALIVE = $00000020; // 需要进行连接保持测试
  PF_PEEKING = $00000040; // 正在执行连接保持测试
{$HPPEMIT '#pragma link "qdb"'}

type

  TQFieldDef = class;
  TQSchema = class;
  PQDataSet = ^TQDataSet;
  TQDataSet = class;
  TQProvider = class;
  TQConverter = class;
  TQConverterClass = class of TQConverter;
  TQLocalCheck = class; // TCheckConstraint,TParams.ParseSQL解析SQL脚本
  TQLocalChecks = class;
  TQRecord = class;
  TQFilterExp = class;
{$IFDEF UNICODE}
  TQFieldDefList = TList<TQFieldDef>;
  TQSchemaList = TList<TQSchema>;
  TQDataSetList = TList<TQDataSet>;
  TQRecords = TList<TQRecord>;
  TQFilterExps = TList<TQFilterExp>;
{$ELSE}
  TQFieldDefList = TList;
  TQSchemaList = TList;
  TQDataSetList = TList;
  TQRecords = TList;
  TQFilterExps = TList;
{$ENDIF}
  TQValueDataType = (vdtNull, vdtBoolean, vdtFloat, vdtInteger, vdtInt64,
    vdtCurrency, vdtBcd, vdtGuid, vdtDateTime, vdtInterval, vdtString,
    vdtStream, vdtArray);

  PQValue = ^TQValue;

  /// 一个值对象
  TQValueData = record
    case Integer of
      0:
        (AsBoolean: Boolean);
      1:
        (AsFloat: Double);
      2:
        (AsInteger: Integer);
      3:
        (AsInt64: Int64);
      4:
        (AsBcd: PBcd);
      5:
        (AsGuid: PGuid);
      6:
        (AsDateTime: TDateTime);
      7:
        (AsInterval: TQInterval);
      8:
        (AsString: PQStringW);
      9:
        (AsStream: TMemoryStream);
      10:
        (Size: Cardinal;
          Items: PQValue;
        );
      11:
        (AsCurrency: Currency);
  end;

  TQValue = record
    Value: TQValueData;
    ValueType: TQValueDataType;
  end;

  TQValueHelper = record helper for TQValue
  private
    function GetItems(AIndex: Integer): PQValue; inline;
    function GetCount: Integer; inline;
    function GetAsBcd: TBcd;
    function GetAsBoolean: Boolean;
    function GetAsCurrency: Currency;
    function GetAsDateTime: TDateTime;
    function GetAsGuid: TGuid;
    function GetAsInt64: Int64;
    function GetAsInteger: Integer;
    function GetAsInterval: TQInterval;
    function GetAsStream: TMemoryStream;
    function GetAsString: QStringW;
    function GetIsNull: Boolean;
    procedure SetAsBcd(const AValue: TBcd);
    procedure SetAsBoolean(const AValue: Boolean);
    procedure SetAsCurrency(const AValue: Currency);
    procedure SetAsDateTime(const AValue: TDateTime);
    procedure SetAsGuid(const AValue: TGuid);
    procedure SetAsInt64(const AValue: Int64);
    procedure SetAsInteger(const AValue: Integer);
    procedure SetAsInterval(const AValue: TQInterval);
    procedure SetAsString(const AValue: QStringW);
    function GetAsFloat: Double;
    procedure SetAsFloat(const AValue: Double);
  public
    procedure Reset;
    procedure TypeNeeded(AType: TQValueDataType);
    procedure ArrayNeeded(ALen: Integer);
    procedure Copy(const ASource: TQValue);
    property Items[AIndex: Integer]: PQValue read GetItems;
    property Count: Integer read GetCount;
    property IsNull: Boolean read GetIsNull;
    property AsString: QStringW read GetAsString write SetAsString;
    property AsBoolean: Boolean read GetAsBoolean write SetAsBoolean;
    property AsInteger: Integer read GetAsInteger write SetAsInteger;
    property AsInt64: Int64 read GetAsInt64 write SetAsInt64;
    property AsFloat: Double read GetAsFloat write SetAsFloat;
    property AsBcd: TBcd read GetAsBcd write SetAsBcd;
    property AsGuid: TGuid read GetAsGuid write SetAsGuid;
    property AsDateTime: TDateTime read GetAsDateTime write SetAsDateTime;
    property AsInterval: TQInterval read GetAsInterval write SetAsInterval;
    property AsStream: TMemoryStream read GetAsStream;
    property AsCurrency: Currency read GetAsCurrency write SetAsCurrency;
  end;

  TQValueCompare = function(const V1, V2: PQValue): Integer;

  { 排序表达式内部结构定义 }
  PQSortExp = ^TQSortExp;

  { 编译后的排序表达式 }
  TQSortExp = record
    Field: TQFieldDef; // 排序的字段索引
    { 是否降序排列 }
    { 是否忽略大小写 }
    Desc, IgnoreCase: Boolean; // 是否降序排列
    Next: PQSortExp; { 下一条件 }
  end;

  // 条件过滤表达式的处理
  PQFilterExp = ^TQFilterExp;
  { 过滤条件支持的比较操作符
    foUnknown : 未知
    foEQ : 等于
    foLT : 小于
    foGT : 大于
    foLE : 小于等于
    foGE : 大于等于
    foNotEQ : 不等于
    foLike : 包含，Like操作将被实际转换成foStartWith,foEndWith,foContains
    foNotLike : 不包含
    foStartWith : 以指定的字符串开始
    foEndWith : 以指定的字符串结束
    foContains : 包含
    foRegex : 正则表达式匹配 }
  TQFilterOperator = (foUnknown, foEQ, foLT, foGT, foLE, foGE, foNotEQ, foLike,
    foNotLike, foStartWith, foEndWith, foContains, foRegex);
  { 过滤操作时表达式之间的逻辑关系，内部使用
    fgoUnknown : 未知
    fgoAnd : 并且
    fgoOr : 或者
    fgoDone : 已完成，没有后续的逻辑关系了 }
  TQFilterGroupOperator = (fgoUnknown, fgoAnd, fgoOr, fgoDone);

  { 过滤条件表达式 }
  TQFilterExp = class
    // protected
    // FField: TQFieldDef; // 字段索引
    // FValue: TQValue; // 比较的目标值
    // FCompareOpr: TQFilterOperator; // 比较操作符
    // FNextOpr: TQFilterGroupOperator; // 下一逻辑表达式，最后一个表达式为fgoDone
    // FParent: TQFilterExp; // 父表达式
    // FItems: TList; // 子表达式列表
    // FRegex: TPerlRegEx;
    // function GetCount: Integer;
    // function GetItems(AIndex: Integer): TQFilterExp;
    // public
    // constructor Create; overload;
    // destructor Destroy; override;
    // function Add(AExp: TQFilterExp): Integer; overload; // 添加一个子表达式
    // function Add: TQFilterExp; overload; // 添加一个子表达式
    // procedure Clear; // 清除子表达式
    // property Count: Integer read GetCount; // 子表达式数据
    // property Items[AIndex: Integer]: TQFilterExp read GetItems; // 子表达式列表
    // property Value: TQValue read FValue; // 比较的目标值
    // property CompareOpr: TQFilterOperator read FCompareOpr write FCompareOpr;
    // // 比较操作符
    // property NextOpr: TQFilterGroupOperator read FNextOpr write FNextOpr;
    // // 下一逻辑操作符
    // property Parent: TQFilterExp read FParent; // 父表达式
    // property Field: TQFieldDef read FField write FField; // 关联字段
  end;

  TQValues = array of TQValue;

  TQColumnValue = record
    OldValue: TQValue;
    NewValue: TQValue;
    CurrentValue: PQValue;
  end;

  TQColumnValues = array of TQColumnValue;

  // TQRecord 用于对应单条记录
  TQRecord = class
  private
    FOriginIndex: Integer; // 在克隆时原始数据集中的索引
    FItemIndex: Integer; // 当前数据集中的记录索引
    FSortedIndex: Integer; // 当前排序结果中的记录索引
    FFilteredIndex: Integer; // 当前过滤结果中的记录索引
    FRefCount: Integer; // 引用计数
    FBookmark: Pointer; // 记录对应的书签,指向记录自己
    FBookmarkFlag: TBookmarkFlag; // 书签标志位
    FStatus: TUpdateStatus; // 记录状态
    FOwner: TComponent; // 记录所有者
    FValues: TQColumnValues; // 值列表
    FFields: TQFieldDef; // 字段定义
    procedure ReinitValues;
    procedure ClearValues;
    procedure Assign(const ASource: TQRecord);
  public
    constructor Create(AFields: TQFieldDef); overload;
    destructor Destroy; override;
    property Owner: TComponent read FOwner;
    property OriginIndex: Integer read FOriginIndex; // 在克隆时原始数据集中的索引
    property ItemIndex: Integer read FItemIndex; // 当前数据集中的记录索引
    property SortedIndex: Integer read FSortedIndex; // 当前排序结果中的记录索引
    property FilteredIndex: Integer read FFilteredIndex; // 当前过滤结果中的记录索引
    property RefCount: Integer read FRefCount; // 引用计数
    property Bookmark: Pointer read FBookmark; // 记录对应的书签,指向记录自己
    property BookmarkFlag: TBookmarkFlag read FBookmarkFlag; //
    property Values: TQColumnValues read FValues; // 记录值列表
    property Status: TUpdateStatus read FStatus; // 记录状态
  end;

  PQRecord = ^TQRecord;

  /// <summary>支持的迭代器级别
  /// rilForwardOnly : 只进迭代器，仅支持 First 和 Next 操作
  /// rilBackwardOnly : 只退迭代器，仅支持 Last 和 Prior 操作
  /// rilBidirection : 双向迭代器，支持 First/Last/Prior/Next 操作
  /// riRandom : 随机迭代器，支持First/Last/Next/Prior/MoveTo 操作
  TQRecordIteratorLevel = (rilForwardOnly, rilBackwardOnly, rilBidirection,
    rilRandom);

  /// <summary> TQRecords 接口用于实现一个记录集，TQDataSet、TQConverter 者实现了该
  /// 接口，以便能够实现对数据的遍历
  IQRecords = interface
    function GetRecordCount: Integer; // 获取记录总数
    procedure First; // 到第一条记录
    procedure Last; // 到最后一条记录
    procedure Next; // 下一条记录
    procedure Prior; // 前一条记录
    procedure MoveTo(const AIndex: Cardinal); // 移动到指定的记录
    function ActiveRecord: TQRecord; // 当前记录缓冲区
    function AllocRecord: TQRecord; // 分配一个新的记录
    procedure FreeRecord(ARec: TQRecord); // 释放一个记录
    function GetIteratorType: TQRecordIteratorLevel; // 支持的迭代级别
    procedure GetFieldValue(ARecord: PQRecord; AField: TField;
      const AValue: TQValue);
    procedure SetFieldValue(ARecord: PQRecord; AField: TField;
      var AValue: TQValue);
  end;

  TQFieldDef = class(TFieldDef)
  private
    FSchema: QStringW; // 架构名，如public
    FDatabase: QStringW; // 数据库名
    FTable: QStringW; // 表名
    FBaseName: QStringW; // 数据表中原始的列名
    FDBType: Integer; // 数据字段类型
    FFlags: Integer; // 标志位
    FDBNo: Word; // 数据库中原始字段序列号
    FOnCompare: TQValueCompare; // 字段值的比较方法
    FField: TField; // 关联的字段
    FScale: Word;
    function GetFlags(const Index: Integer): Boolean;
    function GetIsArray: Boolean;
    function GetItems(AIndex: Integer): TQFieldDef;
    procedure SetDBType(const Value: Integer);
    procedure SetField(const Value: TField);
    procedure SetFlags(const Index: Integer; const Value: Boolean);
    procedure SetScale(const Value: Word);
    function GetCount: Integer;
  protected
  public
    constructor Create(Owner: TFieldDefs; const Name: string;
      DataType: TFieldType; Size: Integer; Required: Boolean;
      FieldNo: Integer); override;
    destructor Destroy; override;
    property Items[AIndex: Integer]: TQFieldDef read GetItems; default;
    // 下面的属性对于非本单元来说是只读的
    property Schema: QStringW read FSchema write FSchema;
    property Database: QStringW read FDatabase write FDatabase;
    property Table: QStringW read FTable write FTable;
    property BaseName: QStringW read FBaseName write FBaseName;
    property DBType: Integer read FDBType write SetDBType;
    property Field: TField read FField write SetField;
    property Scale: Word read FScale write SetScale;
    property DBNo: Word read FDBNo write FDBNo;
    property IsPrimary: Boolean index SCHEMA_ISPRIMARY read GetFlags
      write SetFlags;
    property IsIndex: Boolean index SCHEMA_ISINDEX read GetFlags write SetFlags;
    property IsUnique: Boolean index SCHEMA_UNIQUE read GetFlags write SetFlags;
    property Nullable: Boolean index SCHEMA_NULLABLE read GetFlags
      write SetFlags;
    property IsFixed: Boolean index SCHEMA_ISFIXED read GetFlags write SetFlags;
    property IsAutoInc: Boolean index SCHEMA_AUTOINC read GetFlags
      write SetFlags;
    property Visible: Boolean index SCHEMA_VISIBLE read GetFlags write SetFlags;
    property ReadOnly: Boolean index SCHEMA_READONLY read GetFlags
      write SetFlags;
    property IsCalc: Boolean index SCHEMA_CALC read GetFlags write SetFlags;
    property InWhere: Boolean index SCHEMA_INWHERE read GetFlags write SetFlags;
    property Count: Integer read GetCount;
  end;

  // 元数据信息记录
  TQSchema = class
    // private
    // FName: QStringW; // 名称
    // FItems: TQSchemaList; // 子项目列表
    // FParent: TQSchema; // 父对象
    // FFlags: Cardinal; // 元数据信息标志
    // FSize: Word; // 元数据大小（字段）
    // FDBType: Integer; // 数据库原始类型
    // FPrecision: Word; // 精度
    // FScale: Word; // 小数点位数
    // function GetIsDatabase: Boolean;
    // function GetIsField: Boolean;
    // function GetIsFixed: Boolean;
    // function GetIsIndex: Boolean;
    // function GetIsPrimary: Boolean;
    // function GetIsSchema: Boolean;
    // function GetIsTable: Boolean;
    // function GetIsType: Boolean;
    // function GetNullable: Boolean;
    // procedure SetIsDatabase(const Value: Boolean);
    // procedure SetIsField(const Value: Boolean);
    // procedure SetIsFixed(const Value: Boolean);
    // procedure SetIsIndex(const Value: Boolean);
    // procedure SetIsPrimary(const Value: Boolean);
    // procedure SetIsSchema(const Value: Boolean);
    // procedure SetIsTable(const Value: Boolean);
    // procedure SetIsType(const Value: Boolean);
    // procedure SetNullable(const Value: Boolean);
    // function GetCount: Integer;
    // function GetItems(AIndex: Integer): TQSchema;
    // public
    // constructor Create; overload;
    // constructor Create(AName: QStringW; ATypeFlags: Cardinal = 0); overload;
    // destructor Destroy; override;
    // function Find(APath: QStringW): TQSchema; // 查找
    // function Add(AName: QStringW; ATypeFlags: Cardinal = 0): TQSchema; overload;
    // // 添加
    // procedure Add(AItem: TQSchema); overload; // 添加
    // procedure Clear; // 清除
    // property Name: QStringW read FName write FName; // 元数据名称
    // property IsDatabase: Boolean read GetIsDatabase write SetIsDatabase;
    // // 是否是数据库名
    // property IsSchema: Boolean read GetIsSchema write SetIsSchema; // 是否是架构名
    // property IsTable: Boolean read GetIsTable write SetIsTable; // 是否是表名
    // property IsField: Boolean read GetIsField write SetIsField; // 是否是字段名
    // property IsType: Boolean read GetIsType write SetIsType; // 是否是类型名
    // property IsIndex: Boolean read GetIsIndex write SetIsIndex; // 是否是索引
    // property IsPrimary: Boolean read GetIsPrimary write SetIsPrimary; // 是否是主键
    // property Nullable: Boolean read GetNullable write SetNullable; // 是否允许为空
    // property IsFixed: Boolean read GetIsFixed write SetIsFixed; // 是否是固定长度
    // property Size: Word read FSize write FSize; // 大小
    // property DBType: Integer read FDBType write FDBType; // 数据库原始类型
    // property Precision: Word read FPrecision write FPrecision; // 精度
    // property Scale: Word read FScale write FScale; // 小数点位数
    // property Items[AIndex: Integer]: TQSchema read GetItems; // 子项目
    // property Count: Integer read GetCount; // 子项目数
    // property Parent: TQSchema read FParent; // 父项目
  end;

  TQRecordCheckEvent = procedure(ADataSet: TQDataSet; ACheck: TQLocalCheck;
    var Accept: Boolean) of object;
  TQRecordCheckConflictEvent = procedure(ADataSet: TQDataSet;
    ACheck: TQLocalCheck; var AHandled: Boolean) of object;
  /// <summary>
  /// lctUnique - 唯一约束，Expression中指定的字段列表值的组合，在当前数据集中必需唯一
  /// lctDefault - 默认值约束，Expression中指定的值为表达式默认值
  /// lctRangeCheck - 范围约束，Expression中指定的表达式为值边界检查
  /// </summary>
  TQLocalCheckType = (lctUnique, lctDefault, lctRangeCheck);

  TQLocalCheck = class(TCollectionItem)
    // protected
    // FNameHash: Cardinal;
    // FOnCheck: TQRecordCheckEvent;
    // FOnConflict: TQRecordCheckConflictEvent;
    // FCheckExp: TQFilterExp;
    // FValueHashes: TQHashTable;
    // FName: QStringW;
    // FExpr: QStringW;
    // FErrorText: QStringW;
    // FEnabled: Boolean;
    // FCheckType: TQLocalCheckType;
    // procedure SetName(const Value: QStringW);
    // procedure SetEnabled(const Value: Boolean);
    // procedure SetErrorText(const Value: QStringW);
    // procedure SetExpr(const Value: QStringW);
    // procedure SetOnCheck(const Value: TQRecordCheckEvent);
    // procedure SetOnConflict(const Value: TQRecordCheckConflictEvent);
    // procedure SetCheckType(const Value: TQLocalCheckType);
    // function CheckRange: Boolean;
    // function CheckUnique: Boolean;
    // function CheckDefault: Boolean;
    // function ParseDefault: Boolean;
    // function ParseUnique: Boolean;
    // function ParseCheck: Boolean;
    // public
    // destructor Destroy; override;
    // // 执行默认的约束，如果失败返回False，如果成功，返回True
    // function DefaultCheck: Boolean;
    // procedure Assign(Source: TPersistent); override;
    // function GetDisplayName: string; override;
    // published
    // /// <summary>名称</summary>
    // property Name: QStringW read FName write SetName;
    // /// <summary>约束表达式，详细说明:http://www.qdac.cc/?p=638</summary>
    // property Expression: QStringW read FExpr write SetExpr;
    // /// <summary>错误提示文本</summary>
    // /// <remarks>错误提示中可以引用标志符，[Name]为约束名称,[Value]为违反约束的值</remarks>
    // property ErrorText: QStringW read FErrorText write SetErrorText;
    // /// <summary>是否启用本约束规则</summary>
    // property Enabled: Boolean read FEnabled write SetEnabled;
    // /// <summary>用户自定义的约束检查事件，优先于Expression检查</summary>
    // property OnCheck: TQRecordCheckEvent read FOnCheck write SetOnCheck;
    // /// <summary>在发生违反约束时，如何处理</summary>
    // property OnConflict: TQRecordCheckConflictEvent read FOnConflict
    // write SetOnConflict;
    // /// <summary>约束类型</summary>
    // property CheckType: TQLocalCheckType read FCheckType write SetCheckType;
  end;

  TQLocalChecks = class(TCollection)
    // protected
    // FDataSet: TQDataSet;
    // FOnUpdate: TNotifyEvent;
    // function GetItems(Index: Integer): TQLocalCheck;
    // procedure SetItems(Index: Integer; const Value: TQLocalCheck);
    // public
    // constructor Create(AOwner: TQDataSet); overload;
    // function Add: TQLocalCheck; overload;
    // function Find(const Name: QStringW): TQLocalCheck;
    // procedure Update; reintroduce;
    // property Items[Index: Integer]: TQLocalCheck read GetItems
    // write SetItems; default;
    // property OnUpdate: TNotifyEvent read FOnUpdate write FOnUpdate;
    // property DataSet: TQDataSet read FDataSet;
  end;

  TQConvertStep = (csBeforeImport, csLoadFields, csLoadData, csAfterImport,
    csBeforeExport, csSaveFields, csSaveData, csAfterExport);
  TMemoryDataConveterProgress = procedure(ASender: TQConverter;
    AStep: TQConvertStep; AProgress, ATotal: Integer) of object;
  /// <summary>
  /// 导出范围选项
  /// </summary>
  /// <list>
  /// <item><term>merMeta</term><description>元数据（也就是字段定义）</description></item>
  /// <item><term>merUnmodified</term><description>未修改的数据</description></item>
  /// <item><term>merInserted</term><description>新插入的数据</description></item>
  /// <item><term>merModified</term><description>已变更的数据</description></item>
  /// <item><term>merDeleted</term><description>已删除的数据</description></item>
  /// <item><term>merByFiltered</term><description>仅在过滤范围内的数据</description></item>
  /// <item><term>merByPage</term><description>按当前分页中的内容被导出</description></item>
  /// <item><term>merByActiveRecord</term><description>仅当前记录被导出</description></item>
  /// </list>
  /// <remarks>
  /// 如果merByFilter,merByPage,merByCurrentOnly三个选项同时存在，则优先级依次升高
  /// 如[merByFilter,merByPage]等价于merByPage,[merByFilter,merByActiveRecord]等价于
  // merByActiveRecord
  /// </remarks>
  TQExportRange = (merMeta, merUnmodified, merInserted, merModified, merDeleted,
    merByFiltered, merByPage, merByCurrentOnly);
  TQRecordEnumProc = procedure(ASender: TComponent; AIndex: Integer;
    ARecord: TQRecord; AParam: Pointer) of object;
{$IFDEF UNICODE}
  TQRecordEnumProcA = reference to procedure(ASender: TComponent;
    AIndex: Integer; ARecord: TQRecord);
{$ENDIF}
  TQExportRanges = set of TQExportRange;

  TQStreamProcessor = class
  protected
    procedure BeforeSave(ASourceStream: TStream; ADestStream: TStream);
      virtual; abstract;
    procedure BeforeLoad(ASourceStream: TStream; ADestStream: TStream);
      virtual; abstract;
  end;

  TQEncryptProcessor = class(TQStreamProcessor)

  end;

  TQAESEncryptProcessor = class(TQEncryptProcessor)
  protected

  end;

  TQCompressProcessor = class(TQStreamProcessor)

  end;

  TQZLibProcessor = class(TQStreamProcessor)

  end;

  TQLZOProcessor = class(TQStreamProcessor)

  end;

  TQConverter = class(TComponent)
    // protected
    // FExportRanges: TQExportRanges;
    // FOnProgress: TMemoryDataConveterProgress;
    // FStream: TStream;
    // FRootField: TQFieldDef;
    // FEncryptProcessor: TQEncryptProcessor;
    // FCompressProcessor: TQCompressProcessor;
    // procedure SaveToStream(AProvider: TQProvider; AResult: THandle;
    // AStream: TStream); overload;
    // // 用于添加一条记录
    // function AddRecord(ARecord: TQRecord): Boolean;
    // // 分配一条记录
    // function AllocRecord: TQRecord;
    // procedure BeforeImport; virtual;
    // procedure AfterImport; virtual;
    // procedure BeforeExport; virtual;
    // procedure AfterExport; virtual;
    // public
    // constructor Create(AOwner: TComponent); override;
    // destructor Destroy; override;
    // procedure LoadFromStream(ADataSet: TQDataSet; AStream: TStream);
    // // 从流中加载
    // procedure SaveToStream(ADataSet: TQDataSet; AStream: TStream); overload;
    // // 保存数据集到流中
    // procedure LoadFromFile(ADataSet: TQDataSet; AFileName: WideString);
    // // 从文件中加载
    // procedure SaveToFile(ADataSet: TQDataSet; AFileName: WideString);
    // function ForEach(AProc: TQRecordEnumProc; AParam: Pointer): Integer;
    // property RootField: TQFieldDef read FRootField;
    // published
    // // 保存到文件中
    // property ExportRanges: TQExportRanges read FExportRanges
    // write FExportRanges; // 导出范围选择
    // property OnProgress: TMemoryDataConveterProgress read FOnProgress
    // write FOnProgress;
    // property EncryptProcessor: TQEncryptProcessor read FEncryptProcessor
    // write FEncryptProcessor;
    // property CompressProcessor: TQCompressProcessor read FCompressProcessor
    // write FCompressProcessor;
  end;

  { 复制数据来源类型，可取以下值之一：

    <table>
    取值              备注
    --------------  -------------
    dcmUnknown      未知来源
    dcmCurrent      当前显示的数据
    dcmOrigin       更改之前的原始数据
    dcmChanged      变更的数据
    dcmSorted       排序后的数据
    dcmFiltered     按表达式过滤后的数据
    dcmMetaOnly   仅复制表结构，不复制数据
    </table> }
  TQDataCopyMethod = (dcmUnknown, dcmCurrents, dcmOrigins, dcmChanges,
    dcmSorted, dcmFiltered, dcmMetaOnly);

  /// <summary> 数据集打开方法，内部使用</summary>
  /// <list>
  /// <item><term>dsomByCreate</term><description>通过CreateDataSet创建内存数据集</description></item>
  /// <item><term>dsomByProvider</term><description>通过脚本从TQProvider打开</description></item>
  /// <item><term>dsomByConverter</term><description>从转换器加载</description></item>
  /// <item><term>dsomByClone</term><description>从源克隆得到</description></item>
  /// <item><term>dsomByCopy</term><description>从源复制得到</description></item>
  /// </list>
  TQDataSetOpenMethod = (dsomByCreate, dsomByProvider, dsomByConverter,
    dsomByClone, dsomByCopy);

  /// <summary>数据集对象允许的编辑操作</summary>
  /// <list>
  /// <item><term>deaInsert</term><description>插入操作</description></item>
  /// <item><term>deaEdit</term><description>编辑操作</description></item>
  /// <item><term>deaDelete</term><description>删除操作</description></item>
  /// </list>
  TQDataSetEditAction = (deaInsert, deaEdit, deaDelete);
  TQDataSetEditActions = set of TQDataSetEditAction;
  /// <summary>
  /// <list>
  /// <item><term>dmmAppend</term><description>追加到已有的结果集后面</description></item>
  /// <item><term>dmmReplace</term><description>替换已有的结果集</description></item>
  /// <item><term>dmmMerge</term><description>融合，重复的记录会被忽略</description></item>
  /// </list>
  TQDataMergeMethod = (dmmAppend, dmmReplace, dmmMerge);

  TQDataSet = class(TDataSet, IQRecords)
  protected
    FRootField: TQFieldDef; // 根字段
    FProvider: TQProvider; // 数据提供者
    FHandle: THandle; // 从提供者获取数据的句柄，当内存表使用时，始终为空
    FChecks: TQLocalChecks; // 本地约束检查
    // 记录列表
    FOriginRecords: TQRecords; // 原始记录列表
    FChangedRecords: TQRecords; // 变更记录列表
    FFilteredRecords: TQRecords; // 过滤后的记录列表
    FSortedRecords: TQRecords; // 排序后的记录列表
    FActiveRecords: TQRecords; // 当前活动的记录列表，指向上述四个中的某一个
    FOwnerField: TField; // 当自己是一个数据集类型的字段值时，所隶属的字段
    // 克隆支持
    FClones: TQDataSetList; // 从自己克隆出去的数据集列表
    FCloneSource: TQDataSet; // 自己做为克隆后的数据集，那么指向来源数据集
    FOpenBy: TQDataSetOpenMethod; // 数据集打开方式
    FBatchMode: Boolean; // 是否工作在批量模式，批量模式提交数据时，如果关联了Provider不会立即提交
    FReadOnly: Boolean; // 是否允许修改数据集
    FTempState: TDataSetState; // 临时状态
    FIsOpening: Boolean; // 是否正在打开
    FPageIndex: Integer; // 当前页索引
    FPageSize: Integer; // 分页大小
    FCommandText: QStringW;
    FSort: QStringW; // 脚本
    FAllowEditActions: TQDataSetEditActions;
    // 数据集字段支持
    FParentDataSet: TQDataSet;
    FDataSetField: TDataSetField;
    FOnInitFieldDefs: TNotifyEvent; // 用于不使用提供者或转换组件初始化字段定义时触发，用于用户自定义字段
    FOnLoadData: TNotifyEvent; // 用于不使用提供者或转换组件加载数据时

    FCopySource: TQDataSet; // 复制数据来源
    FCopySourceType: TQDataCopyMethod; // 复制数据方式
    FSorted: TList; // 排序后的列表以此为基准遍历
    FFiltered: TList; // 过滤后的列表以此为基准遍历
    FChanged: TList; // 修改过的记录,包含所有添加、修改和删除的记录
    procedure SetProvider(const Value: TQProvider);
    procedure SetCommandText(const Value: QStringW);
    procedure SetPageIndex(const Value: Integer);
    procedure SetPageSize(const Value: Integer);
    procedure SetReadOnly(const Value: Boolean);
    procedure SetSort(const Value: QStringW);
    procedure SetAllowEditActions(const Value: TQDataSetEditActions);
{$IFDEF NEXTGEN}
    function AllocRecBuf: TRecBuf; override;
    procedure FreeRecBuf(var Buffer: TRecBuf); override;
    function GetRecordSize: Word; virtual;
    procedure InternalAddRecord(Buffer: TRecBuf; Append: Boolean);
      overload; override;
{$ELSE}
    function AllocRecordBuffer: TRecordBuffer; override;
    procedure FreeRecordBuffer(var Buffer: TRecordBuffer); override;
{$IF RTLVersion>=19}
    procedure GetBookmarkData(Buffer: TRecordBuffer; Data: TBookmark);
      overload; override;
{$IFEND}
    procedure GetBookmarkData(Buffer: TRecordBuffer; Data: Pointer);
      overload; override;
    function GetBookmarkFlag(Buffer: TRecordBuffer): TBookmarkFlag;
      overload; override;
    procedure InternalAddRecord(Buffer: TRecordBuffer; Append: Boolean);
      overload; override;
    procedure InternalAddRecord(Buffer: Pointer; Append: Boolean);
      overload; override;
{$ENDIF NEXTGEN}
{$IF RTLVersion>=25}// >=XE4
    procedure GetBookmarkData(Buffer: TRecBuf; Data: TBookmark);
      overload; override;
    function GetBookmarkFlag(Buffer: TRecBuf): TBookmarkFlag; overload;
      override;
{$IFEND}
    function GetRecordSize: Word; virtual;
    procedure InternalAddRecord(Buffer: TRecBuf; Append: Boolean);
      overload; override;
  public
    procedure MoveTo(const AIndex: Cardinal); // 移动到指定的记录
    function ActiveRecord: TQRecord; // 当前记录缓冲区
    function AllocRecord: TQRecord; // 分配一个新的记录
    procedure FreeRecord(ARec: TQRecord); // 释放一个记录
    function GetIteratorType: TQRecordIteratorLevel; // 支持的迭代级别
    procedure GetFieldValue(ARecord: PQRecord; AField: TField;
      const AValue: TQValue);
    procedure SetFieldValue(ARecord: PQRecord; AField: TField;
      var AValue: TQValue);
    function ForEach(AProc: TQRecordEnumProc; AParam: Pointer)
      : Integer; overload;
{$IFDEF UNICODE}
    function ForEach(AProc: TQRecordEnumProcA): Integer; overload;
{$ENDIF}
    function Merge(const ACmdText: QStringW; AType: TQDataMergeMethod;
      AWaitDone: Boolean): Boolean;
    property RootField: TQFieldDef read FRootField;
    property Handle: THandle read FHandle;
  published
    property Provider: TQProvider read FProvider write FProvider;
    property CommandText: QStringW read FCommandText write SetCommandText;
    property PageSize: Integer read FPageSize write SetPageSize;
    property PageIndex: Integer read FPageIndex write SetPageIndex;
    property ReadOnly: Boolean read FReadOnly write SetReadOnly;
    property Sort: QStringW read FSort write SetSort;
    /// <summary>批量模式切换开关，在批量模式下，数据变更不会提交，除非手动调用ApplyChanges</summary>
    property BatchMode: Boolean read FBatchMode write FBatchMode default True;
    property Checks: TQLocalChecks read FChecks;
    property Active default false;
    property AllowEditActions: TQDataSetEditActions read FAllowEditActions
      write SetAllowEditActions;
    property AutoCalcFields;
    property DataSetField;
    { <summary> 过滤条件，支持以下运算符：
      运算符         备注
      ----------  ---------------
      =           等于
      \>          大于
      \>=         大于等于
      \<          小于
      \<=         小于等于
      !=或\<\>     不等于
      \* 或 like   包含
      nlike       不包含
      ~           匹配正则表达式
      (           分组开始
      )           分组结束
      and         两个表达式之间是“并且”关系
      or          两个表达式之间是“或”关系
      </summary>
      <remarks>表达式之间按照从左到右的优先级进行运算</remarks> }
    property Filter;
    property Filtered;
    property FilterOptions;
    property BeforeOpen;
    property AfterOpen;
    property BeforeClose;
    property AfterClose;
    property BeforeInsert;
    property AfterInsert;
    property BeforeEdit;
    property AfterEdit;
    property BeforePost;
    property AfterPost;
    property BeforeCancel;
    property AfterCancel;
    property BeforeDelete;
    property AfterDelete;
    property BeforeScroll;
    property AfterScroll;
    property BeforeRefresh;
    property AfterRefresh;
    property OnCalcFields;
    property OnDeleteError;
    property OnEditError;
    property OnFilterRecord;
    property OnNewRecord;
    property OnPostError;
  end;
  /// <summary>事务隔离级别，具体支持程度由数据库本身决定，如果不支持，会转换为比较接近的级别</summary>
  /// dilUnspecified - 未指定，一般会转换为dilReadCommited
  /// dilReadCommited - 读取已经提交的数据
  /// dilReadUncommited - 允许读取未提交的数据（脏读）
  /// dilRepeatableRead - 循环读
  /// dilSerializable - 串行
  /// dilSnapshot - 快照

  TQDBIsolationLevel = (dilUnspecified, dilReadCommitted, dilReadUncommitted,
    dilRepeatableRead, dilSerializable, dilSnapshot);

  /// <summary>TQCommand用于SQL脚本相关信息记录</summary>
  TQCommand = record
    Name: QStringW;
    DataObject: TObject;
    SQL: QStringW;
    Params: TParams;
    Prepared: Boolean;
  end;

  TQExecuteStatics = record
    QueuedTime: Int64; // 请求投寄时间
    StartTime: Int64; // 请求开始时间
    PreparedTime: Int64; // 准备就绪时间
    ExecuteStartTime: Int64; // 脚本开始执行时间
    ExecuteDoneTime: Int64; // 执行完成时间
    StopTime: Int64; // 执行完成时间
    LoadedTime: Int64; // 加载完成
    AffectRows: Integer; // 影响的行数
  end;

  TQExecuteResult = record
    Statics: TQExecuteStatics; // 运行统计信息
    ErrorCode: Cardinal; // 错误代码
    ErrorMsg: QStringW; // 错误提示
  end;

  /// <summary>命令被发往数据库执行脚本前触发的事件</summary>
  /// <params>
  /// <param name="ASender">当前执行的Provider对象</param>
  /// <param name="ACommand">当前要执行的脚本对象</param>
  /// </params>
  TQBeforeExecuteEvent = procedure(ASender: TQProvider;
    const ACommand: TQCommand) of object;
  /// <summary>在命令执行完成后触发的事件</summary>
  /// <params>
  /// <param name="ASender">提供者对象</param>
  /// <param name="ACommand">执行的命令对象</param>
  /// <param name="AResult">执行结果</param>
  /// </params>
  TQAfterExecuteEvent = procedure(ASender: TQProvider;
    const ACommand: TQCommand; const AResult: TQExecuteResult) of object;

  // 内部记录执行参数的相关记录
  TQSQLRequest = record
    Command: TQCommand; // 命令
    WaitResult: Boolean; // 如果不为空，则等待结果完成，如果为空，则不等待
    Result: TQExecuteResult; // 执行结果
    AfterOpen: TQAfterExecuteEvent; // 执行完成回调事件
  end;

  /// <summary>通知信息级别</summary>
  TQNoticeLevel = (nlLog, nlInfo, nlDebug, nlNotice, nlWarning, nlError,
    nlPanic, nlFatal);

  TQServerNotificationEvent = procedure(ASender: TQProvider;
    ALevel: TQNoticeLevel; const AMsg: QStringW) of object;

  TQServerNotifyEvent = procedure(ASender: TQProvider;
    const AName, APayload: QStringW) of object;

  TQProvider = class(TComponent)
    // protected
    // FProviderName: QStringW; // 唯一名称标志
    // FDatabase: QStringW; // 数据库表
    // FSchema: QStringW; // 连接到的模式名
    // FErrorCode: Cardinal; // 末次错误代码
    // FErrorMsg: QStringW; // 末次错误消息
    // FOnNotify: TQServerNotifyEvent;
    // // 连接相关事件
    // FBeforeConnect: TNotifyEvent;
    // FAfterConnected: TNotifyEvent;
    // FBeforeDisconnect: TNotifyEvent;
    // FAfterDisconnect: TNotifyEvent;
    // FOnParamChanged: TNotifyEvent;
    // // 执行相关事件
    // FBeforeExecute: TQBeforeExecuteEvent; // 执行脚本前触发的事件
    // FAfterExecute: TQAfterExecuteEvent; // 执行脚本完成后触发的事件
    // FOnServerNotification: TQServerNotificationEvent;
    // FTransactionLevel: Integer; // 事务嵌套级别
    // FParams: TStringList; // 命令参数
    // FHandle: THandle; // 由底层驱动返回的连接句柄
    // FCommandTimeout: Cardinal; // 命令超时
    // FConnectionString: QStringW; // 连接字符串
    // FCached: TQDataSetList; // 缓存的数据集对象
    // FDataSets: TQDataSetList; // 关联的数据集对象
    // FPeekInterval: Integer;
    // FFlags: Integer;
    // procedure DoParamChanged(); virtual;
    // procedure SetConnectionString(const Value: QStringW);
    // { 释放一个由Execute返回的结果句柄
    // Parameters
    // AHandle :  要释放的句柄，由Execute函数返回 }
    // procedure DestroyHandle(AHandle: THandle); virtual; abstract;
    // procedure SetError(ACode: Cardinal; const AMsg: QStringW);
    // procedure SetParams(const Value: TStrings);
    // procedure SetConnected(const Value: Boolean);
    // { 获取指定的连接字符串列表，注意内部使用UTF8编码，如果包含中文等字符应先转为UTF8编码 }
    // function GetParams: TStrings;
    // function GetConnected: Boolean;
    // { 获取指定结果集总记录数
    // Parameters
    // AHandle :  由Execute返回的结果句柄
    //
    // Returns
    // 返回实际的记录数 }
    // function GetRecordCount(AHandle: THandle): Integer; virtual; abstract;
    // { 返回结果中包含的字段数量
    // Parameters
    // AHandle :  由Execute返回的结果句柄 }
    // function GetFieldCount(AHandle: THandle): Integer; virtual; abstract;
    // { 获取指定的结果句柄中，受影响的记录行数
    // Parameters
    // AHandle :  由Execute返回的结果句柄
    //
    // Returns
    // 返回受影响的行数 }
    // function GetAffectedCount(AHandle: THandle): Integer; virtual; abstract;
    // { 获取指定的字段定义
    // Parameters
    // AHandle :  由Execute返回的结果句柄
    // AIndex :   字段索引
    // ADef :     返回的实际定义
    //
    // Returns
    // 成功，返回true，失败，返回false }
    // function GetFieldDef(AHandle: THandle; AIndex: Integer;
    // var ADef: TQFieldDef): Boolean; virtual; abstract;
    // { 获取指定字段的内容
    // Parameters
    // AHandle :    由Execute返回的结果句柄
    // ARowIndex :  记录行号
    // AField :     字段定义
    // AVal :       具体内容
    //
    // Returns
    // 如果成功获取到值（即使是空值，也是成功获取到），返回true，否则，返回false }
    // function GetFieldData(AHandle: THandle; ARowIndex: Integer;
    // AField: TQFieldDef; AVal: TQValue): Boolean; virtual; abstract;
    // /// <summary>执行指定的脚本</summary>
    // /// <params>
    // /// <param name="ARequest">命令执行参数</param>
    // /// </params>
    // /// <returns>成功，返回原始结果句柄，失败，返回-1。</returns>
    // function InternalExecute(var ARequest: TQSQLRequest): THandle;
    // virtual; abstract;
    // { 执行实际的关闭连接动作 }
    // procedure InternalClose; virtual; abstract;
    // { 执行实际的建立连接动作 }
    // procedure InternalOpen; virtual; abstract;
    // { 内部执行实际的更新操作
    // Parameters
    // ARootField :  根字段，它可能隶属于一个数据集，也可能是临时创建的一个对象
    // ARecords :    要更新的记录列表 }
    // procedure InternalApplyUpdates(ARootField: TQFieldDef;
    // ARecords: TQRecords); virtual;
    // { 组件加载完成后，检查属性，以确定是否连接（如Connected在设计时设置为True) }
    // procedure Loaded; override;
    // /// <summary>执行指定的脚本</summary>
    // /// <params>
    // /// <param name="ARequest">命令执行参数</param>
    // /// </params>
    // /// <returns>成功，返回原始结果句柄，失败，返回-1。</returns>
    // function Execute(var ARequest: TQSQLRequest): THandle; virtual;
    // procedure KeepAliveNeeded; virtual;
    // procedure Notification(AComponent: TComponent;
    // Operation: TOperation); override;
    // procedure SetKeepAlive(const Value: Boolean);
    // procedure SetPeekInterval(const Value: Integer);
    // procedure DoLivePeek(AJob: PQJob);
    // function GetConnectionString: QStringW;
    // function GetFlags(const Index: Integer): Boolean;
    // procedure SetFlags(AFlag: Integer; AValue: Boolean);
    // procedure InternalSetParams(ADest: TParams; const ASource: array of const);
    // procedure InitializeRequest(var ARequest: TQSQLRequest;
    // const ASQL: QStringW; ACreateParams: Boolean);
    // procedure InternalApplyUpdate(ADataSource: TObject); virtual;
    // function PrepareChangeRequest(var ARequest: TQSQLRequest;
    // AUpdatStatus: TUpdateStatus): Boolean; virtual;
    // public
    // constructor Create(AOwner: TComponent); override;
    // destructor Destroy; override;
    // { 内部使用，析构前进行一些清理工作 }
    // procedure BeforeDestruction; override;
    // /// <summary>打开连接</summary>
    // /// <returns>如果成功，返回true，如果失败，返回false</returns>
    // function Open: Boolean;
    // // OpenStream函数
    //
    // function OpenStream(ACmdText: QStringW; AStreamFormat: TQConverterClass)
    // : TMemoryStream; overload;
    // function OpenStream(AStream: TStream; ACmdText: QStringW;
    // AStreamFormat: TQConverterClass): Boolean; overload; virtual;
    // function OpenStream(AStream: TStream; ASQL: TQCommand;
    // AStreamFormat: TQConverterClass): Boolean; overload; virtual;
    // function OpenStream(ASQL: TQCommand; AStreamFormat: TQConverterClass)
    // : TMemoryStream; overload;
    // function OpenStream(AStream: TStream; ACmdText: QStringW;
    // AStreamFormat: TQConverterClass; AParams: array of const)
    // : Boolean; overload;
    // function OpenStream(ACmdText: QStringW; AStreamFormat: TQConverterClass;
    // AParams: array of const): TMemoryStream; overload;
    // function OpenStream(ACmdText: QStringW; AStreamFormat: TQConverter)
    // : TMemoryStream; overload;
    // function OpenStream(AStream: TStream; ACmdText: QStringW;
    // AStreamFormat: TQConverter): Boolean; overload; virtual;
    // function OpenStream(AStream: TStream; ASQL: TQCommand;
    // AStreamFormat: TQConverter): Boolean; overload; virtual;
    // function OpenStream(ASQL: TQCommand; AStreamFormat: TQConverter)
    // : TMemoryStream; overload;
    // function OpenStream(AStream: TStream; ACmdText: QStringW;
    // AStreamFormat: TQConverter; AParams: array of const): Boolean; overload;
    // function OpenStream(ACmdText: QStringW; AStreamFormat: TQConverter;
    // AParams: array of const): TMemoryStream; overload;
    //
    // // OpenDataSet函数
    //
    // function OpenDataSet(ACmdText: QStringW): TQDataSet; overload;
    // function OpenDataSet(ADataSet: TQDataSet; ACmdText: QStringW;
    // AfterOpen: TQAfterExecuteEvent = nil): Boolean; overload; virtual;
    // function OpenDataSet(ADataSet: TQDataSet; ASQL: TQCommand;
    // AfterOpen: TQAfterExecuteEvent = nil): Boolean; overload; virtual;
    // function OpenDataSet(ADataSet: TQDataSet; ACmdText: QStringW;
    // AParams: array of const; AfterOpen: TQAfterExecuteEvent = nil)
    // : Boolean; overload;
    // function OpenDataSet(ACmdText: QStringW; AParams: array of const)
    // : TQDataSet; overload;
    //
    // // ExecuteCmd函数
    //
    // function ExecuteCmd(ACmdText: QStringW): Integer; overload; virtual;
    // function ExecuteCmd(AParams: TQCommand): Integer; overload; virtual;
    // function ExecuteCmd(ACmdText: QStringW; const AParams: array of const)
    // : Integer; overload;
    //
    // // Prepare
    // /// <summary>准备一个SQL脚本，以便重复执行</summary>
    // /// <params>
    // /// <param name="ACmdText">要执行的SQL脚本</param>
    // /// </params>
    // /// <returns>成功，返回准备完成的SQL语句对象，可以用于OpenStream/OpenDataSet/ExecuteCmd语句</returns>
    // /// <remarks>返回的TQCommand对象需要手动释放
    // function Prepare(ACmdText: QStringW; AName: QStringW = '')
    // : TQCommand; virtual;
    // /// <summary> 开启事务或保存点</summary>
    // /// <params>
    // /// <param name="ALevel">新事务的事务隔离级别，默认为diUnspecified，由数据库决定</param>
    // /// <param name="ASavePointName">数据库事务保存点名称</param>
    // /// </params>
    // /// <returns>成功开启事务，返回true，否则，返回false</returns>
    // function BeginTrans(ALevel: TQDBIsolationLevel = dilUnspecified;
    // ASavePointName: QStringW = ''): Boolean; virtual;
    //
    // { 判断是否存在指定的物理表（不包含视图）
    // Parameters
    // ATableName :  要判断的表名
    //
    // Returns
    // 存在，返回true，不存在，返回false }
    // function TableExists(ATableName: QStringW): Boolean; virtual;
    // { 判断指定的视图是否存在
    // Parameters
    // AName :  要判断的视图名称
    //
    // Returns
    // 存在，返回true，不存在，返回false }
    // function ViewExists(AName: QStringW): Boolean; virtual;
    // { 判断指定的函数是否存在
    // Parameters
    // AName :  要判断的函数名称 }
    // function FunctionExists(AName: QStringW): Boolean; virtual;
    // { 判断是否存在指定的存贮过程
    // Parameters
    // AName :  要判断的存贮过程名
    //
    // Returns
    // 存在，返回true，否则，返回false }
    // function ProcedureExists(AName: QStringW): Boolean; virtual;
    // { 判断指定的触发器是否存在
    // Parameters
    // AName :  要判断的触发器名称
    //
    // Returns
    // 存在，返回true，不存在，返回false }
    // function TriggerExists(AName: QStringW): Boolean; virtual;
    // { 判断指定表的指定字段是否存在,如果存在，返回true
    // Parameters
    // ATableName :  表名
    // AColName :    列名 }
    // function ColumnExists(ATableName, AColName: QStringW): Boolean; virtual;
    // { 判断指定的脚本是否返回至少一条记录
    // Parameters
    // ACmdText :  要执行的脚本
    //
    // Returns
    // 如果返回一个结果集，并且至少返回一条记录，则返回True，否则返回false
    //
    //
    // Remarks
    // 传递的命令脚本是实际被执行的，因此，如果包含了修改数据的命令，请做好相应的事务处理。 }
    // function RecordExists(ACmdText: QStringW): Boolean;
    // procedure CommitTrans; virtual; // 提交事务
    // procedure RollbackTrans(ASavePointName: QStringW = ''); virtual;
    // { 回滚事务或保存点
    // Parameters
    // ASavePointName :  保存点名称，为空表示还原事务，否则是还原保存点 }
    // procedure Close; // 关闭连接
    // procedure ApplyUpdates(ADataSet: TQDataSet); overload; virtual;
    // { 将指定数据集的变更内容应用到数据库中
    // Parameters
    // ADataSet :  要更新的数据集对象 }
    // { 将指定流中的变更内容应用到数据库中
    // Parameters
    // AStream :  源数据流
    // AFormat :  数据流内容的格式转换器类型 }
    // procedure ApplyUpdates(AStream: TStream; AFormat: TQConverterClass);
    // overload; virtual;
    // { 将指定文件中的变更信息应用
    // Parameters
    // AFileName :  文件名
    // AFormat :    文件格式转换器类型 }
    // procedure ApplyUpdates(AFileName: QStringW; AFormat: TQConverterClass);
    // overload; virtual;
    //
    // { 从缓存中分配一个数据集对象，如果不存在，就创建一个新的数据集对象返回。 }
    // function AcquireDataSet: TQDataSet;
    // { 将一个由OpenDataSet或AcquireDataSet返回的数据集对象交还回缓冲池 }
    // procedure ReleaseDataSet(ADataSet: TQDataSet);
    // /// <summary>监听服务器上指定名称的通知</summary>
    // /// <param name="AName">要监听的通知名称</param>
    // procedure Listen(const AName: QStringW); virtual;
    // /// <summary>取消对指定名称的通知的监听</summary>
    // procedure Unlisten(const AName: QStringW); virtual;
    // /// <summary>触发服务器上特定名称的通知</summary>
    // /// <param name="AName">要发送的通知名称</param>
    // /// <param name="APayload">要发送的通知内容字符串</param>
    // procedure Notify(const AName: QStringW; const APayload: QStringW); virtual;
    //
    // property ProviderName: QStringW read FProviderName; // 名称标志
    // property LastError: Cardinal read FErrorCode; // 末次错误代码
    // property LastErrorMsg: QStringW read FErrorMsg; // 末次错误消息内容
    // property TransactionLevel: Integer read FTransactionLevel;
    // // 事务隔离级别;//事务隔离级别
    // property Handle: THandle read FHandle;
    // published
    // property BeforeExecute: TQBeforeExecuteEvent read FBeforeExecute
    // write FBeforeExecute; // 执行脚本前触发事件
    // property AfterExecute: TQAfterExecuteEvent read FAfterExecute
    // write FAfterExecute; // 执行脚本后触发事件
    // property BeforeConnect: TNotifyEvent read FBeforeConnect
    // write FBeforeConnect; // 连接建立前触发
    // property AfterConnected: TNotifyEvent read FAfterConnected
    // write FAfterConnected; // 连接建立后触发
    // property BeforeDisconnect: TNotifyEvent read FBeforeDisconnect
    // write FBeforeDisconnect; // 连接断开前触发
    // property AfterDisconnect: TNotifyEvent read FAfterDisconnect
    // write FAfterDisconnect; // 连接断开后触发
    // property OnParamChanged: TNotifyEvent read FOnParamChanged
    // write FOnParamChanged;
    // property OnServerNotification: TQServerNotificationEvent
    // read FOnServerNotification write FOnServerNotification;
    // property OnNotify: TQServerNotifyEvent read FOnNotify write FOnNotify;
    // property ConnectParams: TStrings read GetParams write SetParams;
    // // 连接参数，注意使用的应为UTF8编码
    // property Connected: Boolean read GetConnected write SetConnected; // 是否已连接
    // property ConnectionString: QStringW read GetConnectionString
    // write SetConnectionString; // 连接字符串
    // property CommandTimeout: Cardinal read FCommandTimeout write FCommandTimeout
    // default 30; { 命令执行超时时间，对于部分提供者对象，可能无意义 }
    // property Connecting: Boolean Index PF_CONNECTING read GetFlags; // 是否正在连接数据库
    // property Closing: Boolean Index PF_CLOSING read GetFlags;
    // property Executing: Boolean Index PF_EXECUTING read GetFlags;
    // property Peeking: Boolean Index PF_PEEKING read GetFlags;
    // property KeepAlive: Boolean Index PF_KEEPALIVE read GetFlags;
    // property PeekInterval: Integer read FPeekInterval write SetPeekInterval;
  end;

resourcestring
  SValueNotArray = '当前值不是数组类型，无法按数组方式访问。';

const
  QValueTypeName: array [TQValueDataType] of String = ('NULL', 'Boolean',
    'Float', 'Integer', 'Int64', 'Currency', 'Bcd', 'Guid', 'DateTime',
    'Interval', 'String', 'Stream', 'Array');

implementation

uses math;

resourcestring
  SBadTypeConvert = '无效的类型转换:%s->%s';
  SConvertError = '无法将 %s 转换为 %s 类型的值。';
  SCantCompareField = '指定的字段类型 [%s] 不能进行比较操作。';
  SOutOfRange = '索引 %d 越界。';
  SUnsupportDataType = '不支持的字段类型 %s';
  SNotArrayType = '%s 不是ftArray,ftObject,ftADT之一。';
  SNotConnected = '未连接到数据库，请先连接到数据库。';
  SEmptySQL = '未指定要执行的SQL脚本内容.';
  SUpdateNotSupport = '[%s] 对应的驱动程序不支持更新操作。';
  SCantConnectToDB = '无法建立与数据库的连接，错误代码:%d,错误信息:'#13#10'%s';
  SUnsupportParamValue = '不支持的参数值类型';
  SUnsupportRecordOwner = '不支持的记录所有者类型。';
  SVarExists = '名为 %s 的函数或变量已经存在。';
  SUnsupportFunction = '不支持的函数 %s。';

const
  SQLTypeMap: array [TFieldType] of Cardinal = (
    // ftUnknown, ftString, ftSmallint, ftInteger, ftWord,// 0..4
    SQL_UNKNOWN, SQL_VARCHAR, SQL_SMALLINT, SQL_INTEGER, SQL_WORD,
    // ftBoolean, ftFloat, ftCurrency, ftBCD, ftDate, ftTime, ftDateTime,// 5..11
    SQL_BOOLEAN, SQL_FLOAT, SQL_MONEY, SQL_BCD, SQL_DATE, SQL_TIME,
    SQL_DATETIME,
    // ftBytes, ftVarBytes, ftAutoInc, ftBlob, ftMemo, ftGraphic, ftFmtMemo, // 12..18
    SQL_BYTES, SQL_VARBYTES, SQL_SERIAL, SQL_LARGEOBJECT, SQL_TEXT,
    SQL_PICTURE, SQL_TEXT,
    // ftParadoxOle, ftDBaseOle, ftTypedBinary, ftCursor, ftFixedChar, ftQStringW, // 19..24
    SQL_OLE, SQL_OLE, SQL_LARGEOBJECT, SQL_CURSOR, SQL_CHAR, SQL_WIDEVARCHAR,
    // ftLargeint, ftADT, ftArray, ftReference, ftDataSet, ftOraBlob, ftOraClob, // 25..31
    SQL_INT64, SQL_ADT, SQL_ARRAY, SQL_REFERENCE, SQL_DATASET, SQL_LARGEOBJECT,
    SQL_WIDETEXT,
    // ftVariant, ftInterface, ftIDispatch, ftGuid, ftTimeStamp, ftFMTBcd, // 32..37
    SQL_VARIANT, SQL_INTERFACE, SQL_IDISPATCH, SQL_GUID, SQL_TIMESTAMP, SQL_BCD,
    // ftFixedWideChar, ftWideMemo, ftOraTimeStamp, ftOraInterval, // 38..41
    SQL_WIDECHAR, SQL_WIDETEXT, SQL_TIMESTAMP, SQL_INTERVAL,
    // ftLongWord, ftShortint, ftByte, ftExtended, ftConnection, ftParams, ftStream, //42..48
    SQL_DWORD, SQL_TINYINT, SQL_BYTE, SQL_EXTENDED, SQL_CONNECTION, SQL_PARAMS,
    SQL_STREAM,
    // ftTimeStampOffset, ftObject, ftSingle
    SQL_TIMEOFFSET, SQL_OBJECT, SQL_SINGLE);

function DBType2FieldType(AType: Cardinal): TFieldType;
begin
case AType of
  SQL_TINYINT:
    Result := ftShortint;
  SQL_BYTE:
    Result := ftByte;
  SQL_SMALLINT:
    Result := ftSmallint;
  SQL_WORD:
    Result := ftWord;
  SQL_INTEGER:
    Result := ftInteger;
  SQL_DWORD:
    Result := ftLongword;
  SQL_INT64:
    Result := ftLargeint;
  SQL_QWORD:
    Result := ftLargeint;
  SQL_SMALLSERIAL:
    Result := ftSmallint;
  SQL_SERIAL:
    Result := ftInteger;
  SQL_BIGSERIAL:
    Result := ftLargeint;
  SQL_SINGLE:
    Result := ftSingle;
  SQL_FLOAT:
    Result := ftFloat;
  SQL_BCD:
    Result := ftBcd;
  SQL_MONEY:
    Result := ftCurrency;
  SQL_SMALLMONEY:
    Result := ftCurrency;
  SQL_EXTENDED:
    Result := ftFloat;
  // 字符串类型
  SQL_CHAR:
    Result := ftFixedChar;
  SQL_VARCHAR:
    Result := ftString;
  SQL_WIDECHAR:
    Result := ftFixedWideChar;
  SQL_WIDEVARCHAR:
    Result := ftWideString;
  SQL_TEXT:
    Result := ftMemo;
  SQL_WIDETEXT:
    Result := ftWideMemo;
  SQL_XML:
    Result := ftWideMemo;
  SQL_JSON:
    Result := ftWideMemo;
  SQL_BYTES:
    Result := ftBytes;
  SQL_BIT:
    Result := ftBytes;
  SQL_VARBIT:
    Result := ftVarBytes;
  SQL_VARBINARY:
    Result := ftVarBytes;
  SQL_LARGEOBJECT:
    Result := ftBlob;
  SQL_PICTURE:
    Result := ftGraphic;
  // SQL_STREAM:
  // Result := ftBlob;
  SQL_OLE:
    Result := ftBlob;
  SQL_BOOLEAN:
    Result := ftBoolean; // 布尔
  SQL_UUID:
    Result := ftGuid;
  SQL_BITS:
    Result := ftBytes;
  SQL_VARBITS:
    Result := ftVarBytes;
  // 日期时间类型
  SQL_DATE:
    Result := ftDate;
  SQL_TIME:
    Result := ftTime;
  SQL_SMALLDATETIME:
    Result := ftDateTime;
  SQL_DATETIME:
    Result := ftDateTime;
  SQL_TIMESTAMP:
    Result := ftDateTime;
  SQL_INTERVAL:
    Result := ftOraInterval;
  SQL_TIMEOFFSET:
    Result := ftDateTime;
  SQL_DATASET:
    Result := ftDataSet;
  SQL_CURSOR:
    Result := ftCursor;
  SQL_VARIANT:
    Result := ftVariant;
  SQL_INTERFACE:
    Result := ftInterface;
  SQL_IDISPATCH:
    Result := ftIDispatch;
  SQL_OBJECT:
    Result := ftObject;
  SQL_PARAMS:
    Result := ftParams;
  SQL_CONNECTION:
    Result := ftConnection;
  SQL_REFERENCE:
    Result := ftReference;
  SQL_ARRAY:
    Result := ftArray;
  SQL_ADT:
    Result := ftADT;
  SQL_PG_OID:
    Result := ftLongword;
  SQL_PG_POINT:
    Result := ftObject; //
  SQL_PG_LINE:
    Result := ftObject;
  SQL_PG_LSEG:
    Result := ftObject;
  SQL_PG_BOX:
    Result := ftObject;
  SQL_PG_PATH:
    Result := ftObject;
  SQL_PG_POLYGON:
    Result := ftObject;
  SQL_PG_CIRCLE:
    Result := ftObject;
  SQL_PG_CIDR:
    Result := ftObject;
  SQL_PG_INET:
    Result := ftObject;
  SQL_PG_MACADDR:
    Result := ftString;
  SQL_PG_ROWS:
    Result := ftObject;
  SQL_PG_ACL:
    Result := ftObject;
  SQL_PG_ENUM:
    Result := ftString;
  SQL_PG_TSVECTOR:
    Result := ftString;
  SQL_PG_TSQUERY:
    Result := ftString;
end;
end;
/// 值比较操作，排序或过滤时会使用这些表达式来比较两个值的大小

function Comp_Float_Zero(const V: Double): Integer; inline;
begin
if V > 0 then
  Result := 1
else if V < 0 then
  Result := -1
else
  Result := 0;
end;

/// 布尔 vs *
function Comp_Bool_Bool(const V1, V2: PQValue): Integer;
begin
Result := Ord(V1.Value.AsBoolean) - Ord(V2.Value.AsBoolean);
end;

function Comp_Bool_Float(const V1, V2: PQValue): Integer;
begin
Result := Ord(V1.Value.AsBoolean) - Trunc(V2.Value.AsFloat);
end;

function Comp_Bool_Int(const V1, V2: PQValue): Integer;
begin
Result := Ord(V1.Value.AsBoolean) - V2.Value.AsInteger;
end;

function Comp_Bool_Int64(const V1, V2: PQValue): Integer;
begin
Result := Ord(V1.Value.AsBoolean) - V2.Value.AsInt64;
end;

function Comp_Bool_Bcd(const V1, V2: PQValue): Integer;
begin
Result := Ord(V1.Value.AsBoolean) - Trunc(BcdToDouble(V2.Value.AsBcd^));
end;

function Comp_Bool_DateTime(const V1, V2: PQValue): Integer;
begin
Result := Ord(V1.Value.AsBoolean) - Trunc(V2.Value.AsDateTime);
end;

function Comp_Bool_Currency(const V1, V2: PQValue): Integer;
begin
Result := Ord(V1.Value.AsBoolean) * 10000 - V2.Value.AsInt64;
end;

function Comp_Bool_String(const V1, V2: PQValue): Integer;
var
  b: Boolean;
begin
if TryStrToBool(V2.Value.AsString^, b) then
  Result := Ord(V1.Value.AsBoolean) - Ord(b)
else
  raise EConvertError.CreateFmt(SConvertError, [V2.Value.AsString^, 'bool']);
end;

/// Float vs *

function Comp_Float_Bool(const V1, V2: PQValue): Integer;
begin
Result := Trunc(V1.Value.AsFloat) - Ord(V2.Value.AsBoolean);
end;

function Comp_Float_Float(const V1, V2: PQValue): Integer;
begin
Result := Comp_Float_Zero(V1.Value.AsFloat - V2.Value.AsFloat);
end;

function Comp_Float_Int(const V1, V2: PQValue): Integer;
begin
Result := Comp_Float_Zero(V1.Value.AsFloat - V2.Value.AsInteger);
end;

function Comp_Float_Int64(const V1, V2: PQValue): Integer;
begin
Result := Comp_Float_Zero(V1.Value.AsFloat - V2.Value.AsInt64);
end;

function Comp_Float_Bcd(const V1, V2: PQValue): Integer;
begin
Result := BcdCompare(V1.Value.AsFloat, V2.Value.AsBcd^);
end;

function Comp_Float_DateTime(const V1, V2: PQValue): Integer;
begin
Result := Comp_Float_Float(V1, V2);
end;

function Comp_Float_Currency(const V1, V2: PQValue): Integer;
begin
Result := Comp_Float_Zero(V1.Value.AsFloat - V2.Value.AsCurrency);
end;

function Comp_Float_String(const V1, V2: PQValue): Integer;
var
  T: Double;
begin
if TryStrToFloat(V2.Value.AsString^, T) then
  begin
  Result := Comp_Float_Zero(V1.Value.AsFloat - T);
  end
else
  raise EConvertError.CreateFmt(SConvertError, [V2.Value.AsString^, 'float']);
end;

// Integer vs *
function Comp_Int_Bool(const V1, V2: PQValue): Integer;
begin
Result := V1.Value.AsInteger - Ord(V2.Value.AsBoolean);
end;

function Comp_Int_Float(const V1, V2: PQValue): Integer;
begin
Result := -Comp_Float_Int(V2, V1);
end;

function Comp_Int_Currency(const V1, V2: PQValue): Integer;
begin
Result := V1.Value.AsInteger * Int64(10000) - V2.Value.AsInt64;
end;

function Comp_Int_Int(const V1, V2: PQValue): Integer;
begin
Result := V1.Value.AsInteger - V2.Value.AsInteger;
end;

function Comp_Int_Int64(const V1, V2: PQValue): Integer;
begin
Result := V1.Value.AsInteger - V2.Value.AsInt64;
end;

function Comp_Int_Bcd(const V1, V2: PQValue): Integer;
begin
Result := BcdCompare(V1.Value.AsInteger, V2.Value.AsBcd^);
end;

function Comp_Int_DateTime(const V1, V2: PQValue): Integer;
begin
Result := Comp_Float_Zero(V1.Value.AsInteger - V2.Value.AsDateTime);
end;

function Comp_Int_String(const V1, V2: PQValue): Integer;
var
  T: Integer;
begin
if TryStrToInt(V2.Value.AsString^, T) then
  Result := V1.Value.AsInteger - T
else
  raise EConvertError.CreateFmt(SConvertError, [V2.Value.AsString^, 'int']);
end;

/// Int64 vs *

function Comp_Int64_Bool(const V1, V2: PQValue): Integer;
begin
Result := V1.Value.AsInt64 - Ord(V2.Value.AsBoolean);
end;

function Comp_Int64_Float(const V1, V2: PQValue): Integer;
begin
Result := -Comp_Float_Int64(V2, V1);
end;

function Comp_Int64_Currency(const V1, V2: PQValue): Integer;
begin
Result := V1.Value.AsInt64 * 10000 - V2.Value.AsInt64;
end;

function Comp_Int64_Int(const V1, V2: PQValue): Integer;
begin
Result := V1.Value.AsInt64 - V2.Value.AsInteger;
end;

function Comp_Int64_Int64(const V1, V2: PQValue): Integer;
begin
Result := V1.Value.AsInt64 - V2.Value.AsInt64;
end;

function Comp_Int64_Bcd(const V1, V2: PQValue): Integer;
begin
Result := BcdCompare(V1.Value.AsInt64, V2.Value.AsBcd^);
end;

function Comp_Int64_DateTime(const V1, V2: PQValue): Integer;
begin
Result := Comp_Float_Zero(V1.Value.AsInt64 - V2.Value.AsDateTime);
end;

function Comp_Int64_String(const V1, V2: PQValue): Integer;
var
  T: Int64;
begin
if TryStrToInt64(V2.Value.AsString^, T) then
  Result := V1.Value.AsInt64 - T
else
  raise EConvertError.CreateFmt(SConvertError, [V2.Value.AsString^, 'int64']);
end;

/// Currency vs *
function Comp_Currency_Bool(const V1, V2: PQValue): Integer;
begin
Result := V1.Value.AsInt64 - Ord(V2.Value.AsBoolean) * 10000;
end;

function Comp_Currency_Float(const V1, V2: PQValue): Integer;
begin
Result := Comp_Float_Zero(V1.Value.AsCurrency - V2.Value.AsFloat);
end;

function Comp_Currency_Int(const V1, V2: PQValue): Integer;
begin
Result := V1.Value.AsInt64 - V2.Value.AsInteger * 10000;
end;

function Comp_Currency_Int64(const V1, V2: PQValue): Integer;
begin
Result := V1.Value.AsInt64 - V2.Value.AsInt64 * 10000;
end;

function Comp_Currency_Bcd(const V1, V2: PQValue): Integer;
begin
Result := BcdCompare(V1.Value.AsCurrency, V2.Value.AsBcd^);
end;

function Comp_Currency_DateTime(const V1, V2: PQValue): Integer;
begin
Result := Comp_Float_Zero(V1.Value.AsCurrency - V2.Value.AsDateTime);
end;

function Comp_Currency_String(const V1, V2: PQValue): Integer;
var
  T: Double;
begin
if TryStrToFloat(V2.Value.AsString^, T) then
  Result := Comp_Float_Zero(V1.Value.AsCurrency - T)
else
  raise EConvertError.CreateFmt(SConvertError,
    [V2.Value.AsString^, 'Currency']);
end;

function Comp_Currency_Currency(const V1, V2: PQValue): Integer;
begin
Result := V1.Value.AsInt64 - V2.Value.AsInt64;
end;

/// Bcd vs *

function Comp_Bcd_Bool(const V1, V2: PQValue): Integer;
begin
Result := BcdCompare(V1.Value.AsBcd^, Ord(V2.Value.AsBoolean));
end;

function Comp_Bcd_Float(const V1, V2: PQValue): Integer;
begin
Result := BcdCompare(V1.Value.AsBcd^, V2.Value.AsFloat);
end;

function Comp_Bcd_Currency(const V1, V2: PQValue): Integer;
begin
Result := BcdCompare(V1.Value.AsBcd^, V2.Value.AsCurrency);
end;

function Comp_Bcd_Int(const V1, V2: PQValue): Integer;
begin
Result := BcdCompare(V1.Value.AsBcd^, V2.Value.AsInteger);
end;

function Comp_Bcd_Int64(const V1, V2: PQValue): Integer;
begin
Result := BcdCompare(V1.Value.AsBcd^, V2.Value.AsInt64);
end;

function Comp_Bcd_Bcd(const V1, V2: PQValue): Integer;
begin
Result := BcdCompare(V1.Value.AsBcd^, V2.Value.AsBcd^);
end;

function Comp_Bcd_DateTime(const V1, V2: PQValue): Integer;
begin
Result := BcdCompare(V1.Value.AsBcd^, V2.Value.AsFloat);
end;

function Comp_Bcd_String(const V1, V2: PQValue): Integer;
var
  bcd: TBcd;
begin
if TryStrToBcd(V2.Value.AsString^, bcd) then
  Result := BcdCompare(V1.Value.AsBcd^, V2.Value.AsBcd^)
else
  raise EConvertError.CreateFmt(SConvertError, [V2.Value.AsString^, 'bcd']);
end;

/// Guid

function Comp_Guid_Guid(const V1, V2: PQValue): Integer;
begin
Result := BinaryCmp(@V1.Value.AsGuid^, @V2.Value.AsGuid^, SizeOf(TGuid));
end;

function Comp_Guid_String(const V1, V2: PQValue): Integer;
var
  T: TGuid;
begin
if TryStrToGuid(V2.Value.AsString^, T) then
  Result := BinaryCmp(@V1.Value.AsGuid^, @T, SizeOf(TGuid))
else
  raise EConvertError.CreateFmt(SConvertError, [V2.Value.AsString^, 'guid']);
end;

/// DateTime

function Comp_DateTime_Bool(const V1, V2: PQValue): Integer;
begin
Result := Comp_Float_Zero(V1.Value.AsFloat - Ord(V2.Value.AsBoolean));
end;

function Comp_DateTime_Float(const V1, V2: PQValue): Integer;
begin
Result := Comp_Float_Zero(V1.Value.AsFloat - V2.Value.AsFloat);
end;

function Comp_DateTime_Currency(const V1, V2: PQValue): Integer;
begin
Result := Comp_Float_Zero(V1.Value.AsFloat - V2.Value.AsCurrency);
end;

function Comp_DateTime_Int(const V1, V2: PQValue): Integer;
begin
Result := Comp_Float_Zero(V1.Value.AsFloat - V2.Value.AsInteger);
end;

function Comp_DateTime_Int64(const V1, V2: PQValue): Integer;
begin
Result := Comp_Float_Zero(V1.Value.AsFloat - V2.Value.AsInt64);
end;

function Comp_DateTime_Bcd(const V1, V2: PQValue): Integer;
begin
Result := BcdCompare(V1.Value.AsFloat, V2.Value.AsBcd^);
end;

function Comp_DateTime_DateTime(const V1, V2: PQValue): Integer;
begin
Result := Comp_Float_Zero(V1.Value.AsFloat - V2.Value.AsFloat);
end;

function Comp_DateTime_String(const V1, V2: PQValue): Integer;
var
  T: TDateTime;
begin
if ParseDateTime(PQCharW(V2.Value.AsString^), T) or
  ParseWebTime(PQCharW(V2.Value.AsString^), T) or
  TryStrToDateTime(V2.Value.AsString^, T) then
  Result := Comp_Float_Zero(V1.Value.AsFloat - T)
else
  raise EConvertError.CreateFmt(SConvertError,
    [V2.Value.AsString^, 'TDateTime']);
end;

/// Interval
function Comp_Interval_Interval(const V1, V2: PQValue): Integer;
begin
Result := TQInterval.Compare(V1.Value.AsInterval, V2.Value.AsInterval);
end;

function Comp_Interval_String(const V1, V2: PQValue): Integer;
var
  T: TQInterval;
begin
if T.TryFromString(V2.Value.AsString^) then
  Result := TQInterval.Compare(V1.Value.AsInterval, V2.Value.AsInterval)
else
  raise EConvertError.CreateFmt(SConvertError,
    [V2.Value.AsString^, 'TDateTime']);
end;

/// String

function Comp_String_Bool(const V1, V2: PQValue): Integer;
begin
Result := -Comp_Bool_String(V2, V1);
end;

function Comp_String_Float(const V1, V2: PQValue): Integer;
begin
Result := -Comp_Float_String(V2, V1);
end;

function Comp_String_Currency(const V1, V2: PQValue): Integer;
var
  T: Currency;
begin
if TryStrToCurr(V1.Value.AsString^, T) then
  Result := PInt64(@T)^ - V2.Value.AsInt64
else
  raise EConvertError.CreateFmt(SConvertError,
    [V1.Value.AsString^, 'Currency']);
end;

function Comp_String_Int(const V1, V2: PQValue): Integer;
begin
Result := -Comp_Int_String(V2, V1);
end;

function Comp_String_Int64(const V1, V2: PQValue): Integer;
begin
Result := -Comp_Int64_String(V2, V1);
end;

function Comp_String_Bcd(const V1, V2: PQValue): Integer;
begin
Result := -Comp_Bcd_String(V2, V1);
end;

function Comp_String_Guid(const V1, V2: PQValue): Integer;
begin
Result := -Comp_Guid_String(V2, V1);
end;

function Comp_String_DateTime(const V1, V2: PQValue): Integer;
begin
Result := -Comp_DateTime_String(V2, V1);
end;

function Comp_String_Interval(const V1, V2: PQValue): Integer;
begin
Result := -Comp_Interval_String(V2, V1);
end;

function Comp_String_String(const V1, V2: PQValue): Integer;
begin
Result := StrCmpW(PQCharW(V1.Value.AsString^),
  PQCharW(V2.Value.AsString^), false);
end;

function Comp_String_String_IC(const V1, V2: PQValue): Integer;
begin
Result := StrCmpW(PQCharW(V1.Value.AsString^),
  PQCharW(V2.Value.AsString^), True);
end;

/// Stream vs Stream
function Comp_Stream_Stream(const V1, V2: PQValue): Integer;
var
  L, L1, L2: Int64;
begin
L1 := V1.Value.AsStream.Size;
L2 := V2.Value.AsStream.Size;
if L1 < L2 then
  begin
  Result := BinaryCmp(V1.Value.AsStream.Memory, V2.Value.AsStream.Memory, L1);
  if Result = 0 then
    Result := -1;
  end
else if L1 > L2 then
  begin
  Result := BinaryCmp(V1.Value.AsStream.Memory, V2.Value.AsStream.Memory, L2);
  if Result = 0 then
    Result := 1;
  end
else
  Result := BinaryCmp(V1.Value.AsStream.Memory, V2.Value.AsStream.Memory, L2);
end;

{ TQRecord }
/// <summary>复制另一个记录的值到本记录，注意它不检查太多东西，所以除非你知道干什么，否则不要用</summary>
procedure TQRecord.Assign(const ASource: TQRecord);
var
  L: Integer;
  I: Integer;
begin
FStatus := ASource.Status;
L := High(FValues);
if L > High(ASource.FValues) then
  L := High(ASource.FValues);
for I := 0 to L do
  begin
  FValues[I].OldValue.Copy(ASource.FValues[I].OldValue);
  FValues[I].NewValue.Copy(ASource.FValues[I].NewValue);
  if ASource.FValues[I].CurrentValue = @ASource.FValues[I].NewValue then
    FValues[I].CurrentValue := @FValues[I].NewValue
  else
    FValues[I].CurrentValue := @FValues[I].OldValue;
  end;
end;

procedure TQRecord.ClearValues;
var
  I, C: Integer;
begin
C := High(FValues);
I := 0;
while I <= C do
  begin
  FValues[I].OldValue.Reset;
  FValues[I].NewValue.Reset;
  Inc(I);
  end;
end;

constructor TQRecord.Create(AFields: TQFieldDef);
var
  I: Integer;
begin
inherited Create;
FOriginIndex := -1;
FItemIndex := -1;
FSortedIndex := -1;
FFilteredIndex := -1;
FRefCount := 0;
FBookmark := nil;
FStatus := usUnmodified;
FOwner := AFields.Collection.Owner as TComponent;
FFields := AFields;
ReinitValues;
end;

destructor TQRecord.Destroy;
begin
ClearValues;
inherited;
end;

procedure TQRecord.ReinitValues;
var
  I: Integer;
begin
SetLength(FValues, FFields.Count);
I := 0;
while I < FFields.Count do
  begin
  FValues[I].CurrentValue := @FValues[I].OldValue;
  FValues[I].OldValue.ValueType := vdtNull;
  end;
end;

function LookupCompareProc(ADataType1, ADataType2: TFieldType): TQValueCompare;
begin
Result := nil;
case ADataType1 of
  ftString, ftMemo, ftFixedChar, ftWideString, ftOraClob:
    case ADataType2 of
      ftString, ftMemo, ftFmtMemo, ftFixedChar, ftWideString, ftFixedWideChar,
        ftWideMemo:
        Result := Comp_String_String_IC;
      ftSmallint, ftInteger, ftWord, ftShortint, ftByte, ftCursor:
        Result := Comp_String_Int;
      ftBoolean:
        Result := Comp_String_Bool;
      ftFloat, ftSingle, ftExtended:
        Result := Comp_String_Float;
      ftCurrency:
        Result := Comp_String_Currency;
      ftBcd, ftFMTBcd:
        Result := Comp_String_Bcd;
      ftDate, ftTime, ftDateTime, ftTimeStamp, ftOraTimeStamp,
        ftTimeStampOffset:
        Result := Comp_String_DateTime;
      ftAutoInc, ftLargeint, ftLongword:
        Result := Comp_String_Int64;
      ftGuid:
        Result := Comp_String_Guid;
      ftOraInterval:
        Result := Comp_String_Interval;
    end;
  ftSmallint, ftInteger, ftWord, ftShortint, ftByte, ftCursor:
    case ADataType2 of
      ftString, ftMemo, ftFmtMemo, ftFixedChar, ftWideString, ftFixedWideChar,
        ftWideMemo:
        Result := Comp_Int_String;
      ftSmallint, ftInteger, ftWord, ftShortint, ftByte, ftCursor:
        Result := Comp_Int_Int;
      ftBoolean:
        Result := Comp_Int_Bool;
      ftFloat, ftSingle:
        Result := Comp_Int_Float;
      ftCurrency:
        Result := Comp_Int_Currency;
      ftBcd, ftFMTBcd:
        Result := Comp_Int_Bcd;
      ftDate, ftTime, ftDateTime, ftTimeStamp, ftOraTimeStamp,
        ftTimeStampOffset:
        Result := Comp_Int_DateTime;
      ftAutoInc, ftLargeint, ftLongword:
        Result := Comp_Int_Int64;
    end;
  ftBoolean:
    case ADataType2 of
      ftString, ftMemo, ftFmtMemo, ftFixedChar, ftWideString, ftFixedWideChar,
        ftWideMemo:
        Result := Comp_Bool_String;
      ftSmallint, ftInteger, ftWord, ftShortint, ftByte, ftCursor:
        Result := Comp_Bool_Int;
      ftBoolean:
        Result := Comp_Bool_Bool;
      ftFloat, ftSingle:
        Result := Comp_Bool_Float;
      ftCurrency:
        Result := Comp_Bool_Currency;
      ftBcd, ftFMTBcd:
        Result := Comp_Bool_Bcd;
      ftDate, ftTime, ftDateTime, ftTimeStamp, ftOraTimeStamp,
        ftTimeStampOffset:
        Result := Comp_Bool_DateTime;
      ftAutoInc, ftLargeint, ftLongword:
        Result := Comp_Bool_Int64;
    end;
  ftFloat:
    case ADataType2 of
      ftString, ftMemo, ftFmtMemo, ftFixedChar, ftWideString, ftFixedWideChar,
        ftWideMemo:
        Result := Comp_Float_String;
      ftSmallint, ftInteger, ftWord, ftShortint, ftByte, ftCursor:
        Result := Comp_Float_Int;
      ftBoolean:
        Result := Comp_Float_Bool;
      ftFloat, ftSingle:
        Result := Comp_Float_Float;
      ftCurrency:
        Result := Comp_Float_Currency;
      ftBcd, ftFMTBcd:
        Result := Comp_Float_Bcd;
      ftDate, ftTime, ftDateTime, ftTimeStamp, ftOraTimeStamp,
        ftTimeStampOffset:
        Result := Comp_Float_DateTime;
      ftAutoInc, ftLargeint, ftLongword:
        Result := Comp_Float_Int64;
    end;
  ftCurrency:
    case ADataType2 of
      ftString, ftMemo, ftFmtMemo, ftFixedChar, ftWideString, ftFixedWideChar,
        ftWideMemo:
        Result := Comp_Currency_String;
      ftSmallint, ftInteger, ftWord, ftShortint, ftByte, ftCursor:
        Result := Comp_Currency_Int;
      ftBoolean:
        Result := Comp_Currency_Bool;
      ftFloat, ftSingle:
        Result := Comp_Currency_Float;
      ftCurrency:
        Result := Comp_Currency_Currency;
      ftBcd, ftFMTBcd:
        Result := Comp_Currency_Bcd;
      ftDate, ftTime, ftDateTime, ftTimeStamp, ftOraTimeStamp,
        ftTimeStampOffset:
        Result := Comp_Currency_DateTime;
      ftAutoInc, ftLargeint, ftLongword:
        Result := Comp_Currency_Int64;
    end;
  ftAutoInc, ftLargeint, ftLongword:
    case ADataType2 of
      ftString, ftMemo, ftFmtMemo, ftFixedChar, ftWideString, ftFixedWideChar,
        ftWideMemo:
        Result := Comp_Int_String;
      ftSmallint, ftInteger, ftWord, ftShortint, ftByte, ftCursor:
        Result := Comp_Int_Int;
      ftBoolean:
        Result := Comp_Int_Bool;
      ftFloat, ftSingle:
        Result := Comp_Int_Float;
      ftCurrency:
        Result := Comp_Int_Currency;
      ftBcd, ftFMTBcd:
        Result := Comp_Int_Bcd;
      ftDate, ftTime, ftDateTime, ftTimeStamp, ftOraTimeStamp,
        ftTimeStampOffset:
        Result := Comp_Int_DateTime;
      ftAutoInc, ftLargeint, ftLongword:
        Result := Comp_Int_Int64;
    end;
  ftBcd, ftFMTBcd:
    case ADataType2 of
      ftString, ftMemo, ftFmtMemo, ftFixedChar, ftWideString, ftFixedWideChar,
        ftWideMemo:
        Result := Comp_Bcd_String;
      ftSmallint, ftInteger, ftWord, ftShortint, ftByte, ftCursor:
        Result := Comp_Bcd_Int;
      ftBoolean:
        Result := Comp_Bcd_Bool;
      ftFloat, ftSingle:
        Result := Comp_Bcd_Float;
      ftCurrency:
        Result := Comp_Bcd_Currency;
      ftBcd, ftFMTBcd:
        Result := Comp_Bcd_Bcd;
      ftDate, ftTime, ftDateTime, ftTimeStamp, ftOraTimeStamp,
        ftTimeStampOffset:
        Result := Comp_Bcd_DateTime;
      ftAutoInc, ftLargeint, ftLongword:
        Result := Comp_Bcd_Int64;
    end;
  ftDate, ftTime, ftDateTime, ftTimeStamp, ftOraTimeStamp, ftTimeStampOffset:
    case ADataType2 of
      ftString, ftMemo, ftFmtMemo, ftFixedChar, ftWideString, ftFixedWideChar,
        ftWideMemo:
        Result := Comp_DateTime_String;
      ftSmallint, ftInteger, ftWord, ftShortint, ftByte, ftCursor:
        Result := Comp_DateTime_Int;
      ftBoolean:
        Result := Comp_DateTime_Bool;
      ftFloat, ftSingle:
        Result := Comp_DateTime_Float;
      ftCurrency:
        Result := Comp_DateTime_Currency;
      ftBcd, ftFMTBcd:
        Result := Comp_DateTime_Bcd;
      ftDate, ftTime, ftDateTime, ftTimeStamp, ftOraTimeStamp,
        ftTimeStampOffset:
        Result := Comp_DateTime_DateTime;
      ftAutoInc, ftLargeint, ftLongword:
        Result := Comp_DateTime_Int64;
    end;
  ftGuid:
    case ADataType2 of
      ftString, ftMemo, ftFmtMemo, ftFixedChar, ftWideString, ftFixedWideChar,
        ftWideMemo:
        Result := Comp_Guid_String;
      ftGuid:
        Result := Comp_Guid_Guid;
    end;
  ftOraInterval:
    case ADataType2 of
      ftString, ftMemo, ftFmtMemo, ftFixedChar, ftWideString, ftFixedWideChar,
        ftWideMemo:
        Result := Comp_Interval_String;
      ftOraInterval:
        Result := Comp_Interval_Interval;
    end;
  ftBytes, ftVarBytes, ftStream, ftBlob, ftGraphic, ftTypedBinary, ftOraBlob:
    case ADataType2 of
      ftBytes, ftVarBytes, ftStream, ftBlob, ftGraphic, ftTypedBinary,
        ftOraBlob:
        Result := Comp_Stream_Stream;
    end;
end;
end;
{ TQFieldDef }

constructor TQFieldDef.Create(Owner: TFieldDefs; const Name: string;
  DataType: TFieldType; Size: Integer; Required: Boolean; FieldNo: Integer);
begin
inherited;
FOnCompare := LookupCompareProc(DataType, DataType);
end;

destructor TQFieldDef.Destroy;
begin

inherited;
end;

function TQFieldDef.GetCount: Integer;
begin
Result := ChildDefs.Count;
end;

function TQFieldDef.GetFlags(const Index: Integer): Boolean;
begin
Result := (FFlags and Index) <> 0;
end;

function TQFieldDef.GetIsArray: Boolean;
begin
Result := (DataType = ftArray);
end;

function TQFieldDef.GetItems(AIndex: Integer): TQFieldDef;
begin
Result := inherited ChildDefs[AIndex] as TQFieldDef;
end;

procedure TQFieldDef.SetDBType(const Value: Integer);
var
  I: Integer;
begin
if FDBType <> Value then
  begin
  FDBType := Value;
  DataType := DBType2FieldType(FDBType);
  end;
end;

procedure TQFieldDef.SetField(const Value: TField);
begin
if FField <> Value then
  FField := Value;
end;

procedure TQFieldDef.SetFlags(const Index: Integer; const Value: Boolean);
begin
if Value then
  FFlags := FFlags or Index
else
  FFlags := FFlags and (not Index);

end;

procedure TQFieldDef.SetScale(const Value: Word);
begin
FScale := Value;
end;

{ TQDataSet }

function TQDataSet.ActiveRecord: TQRecord;
begin
Result := TQRecord(ActiveBuffer);
end;

function TQDataSet.AllocRecord: TQRecord;
begin
Result := TQRecord.Create(RootField);
end;

function TQDataSet.AllocRecordBuffer: TRecordBuffer;
begin
Result := TRecordBuffer(AllocRecord);
end;

function TQDataSet.ForEach(AProc: TQRecordEnumProc; AParam: Pointer): Integer;
var
  I: Integer;
begin
if Assigned(AProc) then
  begin
  for I := 0 to FActiveRecords.Count - 1 do
    AProc(Self, I, FActiveRecords[I], AParam);
  end;
end;

function TQDataSet.ForEach(AProc: TQRecordEnumProcA): Integer;
var
  I: Integer;
begin
if Assigned(AProc) then
  begin
  for I := 0 to FActiveRecords.Count - 1 do
    AProc(Self, I, FActiveRecords[I]);
  end;
end;

procedure TQDataSet.FreeRecord(ARec: TQRecord);
begin
FreeObject(ARec);
end;

procedure TQDataSet.FreeRecordBuffer(var Buffer: TRecordBuffer);
begin
FreeRecord(TQRecord(Buffer));
Buffer := nil;
end;

procedure TQDataSet.GetBookmarkData(Buffer: TRecordBuffer; Data: Pointer);
begin
PPointer(Data)^ := TQRecord(Buffer).Bookmark;
end;
{$IF RTLVersion>=19}

procedure TQDataSet.GetBookmarkData(Buffer: TRecordBuffer; Data: TBookmark);
begin
// >=XE3 TBookmark=TArray<Byte> <XE3 TBookmark=TBytes
SetLength(Data, SizeOf(Pointer));
PPointer(@Data[0])^ := TQRecord(Buffer).Bookmark;
end;
{$IFEND}
{$IF RTLVersion>=25}

procedure TQDataSet.GetBookmarkData(Buffer: TRecBuf; Data: TBookmark);
begin
SetLength(Data, SizeOf(Pointer));
PPointer(@Data[0])^ := TQRecord(Buffer).Bookmark;
end;
{$IFEND}

function TQDataSet.GetBookmarkFlag(Buffer: TRecordBuffer): TBookmarkFlag;
begin
Result := TQRecord(Buffer).BookmarkFlag;
end;
{$IF RTLVersion>=25}

function TQDataSet.GetBookmarkFlag(Buffer: TRecBuf): TBookmarkFlag;
begin
Result := TQRecord(Buffer).BookmarkFlag;
end;
{$IFEND}

procedure TQDataSet.GetFieldValue(ARecord: PQRecord; AField: TField;
  const AValue: TQValue);
begin
// Todo:暂时未想到干嘛用:)
end;

function TQDataSet.GetIteratorType: TQRecordIteratorLevel;
begin
Result := rilRandom; // 数据集支持随机迭代器
end;

function TQDataSet.GetRecordSize: Word;
begin

end;

procedure TQDataSet.InternalAddRecord(Buffer: TRecordBuffer; Append: Boolean);
begin

end;

procedure TQDataSet.InternalAddRecord(Buffer: TRecBuf; Append: Boolean);
begin

end;

procedure TQDataSet.InternalAddRecord(Buffer: Pointer; Append: Boolean);
begin

end;

function TQDataSet.Merge(const ACmdText: QStringW; AType: TQDataMergeMethod;
  AWaitDone: Boolean): Boolean;
begin

end;

procedure TQDataSet.MoveTo(const AIndex: Cardinal);
begin
RecNo := AIndex + 1;
end;

procedure TQDataSet.SetAllowEditActions(const Value: TQDataSetEditActions);
begin
if Value <> AllowEditActions then
  FAllowEditActions := Value;
end;

procedure TQDataSet.SetCommandText(const Value: QStringW);
begin
if FCommandText <> Value then
  begin
  if Active then
    Close;
  FCommandText := Value;
  end;
end;

procedure TQDataSet.SetFieldValue(ARecord: PQRecord; AField: TField;
  var AValue: TQValue);
begin

end;

procedure TQDataSet.SetPageIndex(const Value: Integer);
begin

end;

procedure TQDataSet.SetPageSize(const Value: Integer);
begin

end;

procedure TQDataSet.SetProvider(const Value: TQProvider);
begin

end;

procedure TQDataSet.SetReadOnly(const Value: Boolean);
begin
if FReadOnly <> Value then
  begin
  FReadOnly := Value;
  end;
end;

procedure TQDataSet.SetSort(const Value: QStringW);
begin
if Value <> FSort then
  begin
  FSort := Value;
  // Todo:解析并进行排序
  end;
end;

{ TQValueHelper }

procedure TQValueHelper.ArrayNeeded(ALen: Integer);
begin
TypeNeeded(vdtArray);
if Value.Size = 0 then
  GetMem(Value.Items, SizeOf(TQValue) * ALen)
else
  ReallocMem(Value.Items, SizeOf(TQValue) * ALen);
Value.Size := ALen;
end;

procedure TQValueHelper.Copy(const ASource: TQValue);
  procedure CopyArray;
  var
    I: Integer;
  begin
  ArrayNeeded(ASource.Value.Size);
  I := 0;
  while I < ASource.Value.Size do
    begin
    Items[I].Copy(ASource.Items[I]^);
    Inc(I);
    end;
  end;

begin
TypeNeeded(ASource.ValueType);
case ASource.ValueType of
  vdtNull:
    ;
  vdtBoolean:
    Value.AsBoolean := ASource.Value.AsBoolean;
  vdtFloat:
    Value.AsFloat := ASource.Value.AsFloat;
  vdtInteger:
    Value.AsInteger := ASource.Value.AsInteger;
  vdtInt64, vdtCurrency:
    Value.AsInt64 := ASource.Value.AsInt64;
  vdtBcd:
    Value.AsBcd^ := ASource.Value.AsBcd^;
  vdtGuid:
    Value.AsGuid^ := ASource.Value.AsGuid^;
  vdtDateTime:
    Value.AsDateTime := ASource.Value.AsDateTime;
  vdtInterval:
    Value.AsInterval := ASource.Value.AsInterval;
  vdtString:
    Value.AsString^ := ASource.Value.AsString^;
  vdtStream:
    Value.AsStream.CopyFrom(ASource.Value.AsStream, 0);
  vdtArray:
    CopyArray;
end;
end;

function TQValueHelper.GetAsBcd: TBcd;
begin
case ValueType of
  vdtBcd:
    Result := Value.AsBcd^;
  vdtNull:
    Result := 0;
  vdtBoolean:
    Result := Integer(Value.AsBoolean);
  vdtFloat:
    Result := Value.AsFloat;
  vdtInteger:
    Result := Value.AsInteger;
  vdtInt64:
    Result := Value.AsInt64;
  vdtCurrency:
    Result := Value.AsCurrency;
  vdtDateTime:
    Result := Value.AsFloat;
  vdtString:
    Result := StrToBcd(Value.AsString^)
else
  raise EConvertError.CreateFmt(SConvertError, [QValueTypeName[ValueType],
    QValueTypeName[vdtBcd]]);
end;
end;

function TQValueHelper.GetAsBoolean: Boolean;
begin
case ValueType of
  vdtBoolean:
    Result := Value.AsBoolean;
  vdtNull:
    Result := false;
  vdtFloat:
    Result := not IsZero(Value.AsFloat);
  vdtInteger:
    Result := Value.AsInteger <> 0;
  vdtInt64, vdtCurrency:
    Result := Value.AsInt64 <> 0;
  vdtBcd:
    Result := Value.AsBcd^ <> 0;
  vdtDateTime:
    Result := IsZero(Value.AsFloat);
  vdtString:
    Result := StrToBool(Value.AsString^);
else
  raise EConvertError.CreateFmt(SConvertError, [QValueTypeName[ValueType],
    QValueTypeName[vdtBoolean]]);
end;
end;

function TQValueHelper.GetAsCurrency: Currency;
begin
case ValueType of
  vdtCurrency:
    Result := Value.AsCurrency;
  vdtNull:
    Result := 0;
  vdtBoolean:
    Result := Integer(Value.AsBoolean);
  vdtFloat, vdtDateTime:
    Result := Value.AsFloat;
  vdtInteger:
    Result := Value.AsInteger;
  vdtInt64:
    Result := Value.AsInt64;
  vdtBcd:
    Result := BcdToDouble(Value.AsBcd^);
  vdtString:
    Result := StrToCurr(Value.AsString^);
else
  raise EConvertError.CreateFmt(SConvertError, [QValueTypeName[ValueType],
    QValueTypeName[vdtCurrency]]);
end;
end;

function TQValueHelper.GetAsDateTime: TDateTime;
  procedure StrToDT;
  var
    S: String;
  begin
  S := Value.AsString^;
  if TryStrToDateTime(S, Result) or ParseDateTime(PQCharW(S), Result) or
    ParseWebTime(PQCharW(S), Result) then
    Exit;
  raise EConvertError.CreateFmt(SConvertError, [QValueTypeName[ValueType],
    QValueTypeName[vdtDateTime]]);
  end;

begin
case ValueType of
  vdtNull:
    Result := 0;
  vdtBoolean:
    Result := Integer(0);
  vdtFloat:
    Result := Value.AsFloat;
  vdtInteger:
    Result := Value.AsInteger;
  vdtInt64:
    Result := Value.AsInt64;
  vdtCurrency:
    Result := Value.AsCurrency;
  vdtBcd:
    Result := BcdToDouble(Value.AsBcd^);
  vdtDateTime:
    Result := Value.AsDateTime;
  vdtString:
    StrToDT;
else
  raise EConvertError.CreateFmt(SConvertError, [QValueTypeName[ValueType],
    QValueTypeName[vdtDateTime]]);
end;
end;

function TQValueHelper.GetAsFloat: Double;
begin
case ValueType of
  vdtFloat, vdtDateTime:
    Result := Value.AsFloat;
  vdtNull:
    Result := 0;
  vdtBoolean:
    Result := Integer(Value.AsBoolean);
  vdtInteger:
    Result := Value.AsInteger;
  vdtInt64:
    Result := Value.AsInt64;
  vdtCurrency:
    Result := Value.AsCurrency;
  vdtBcd:
    Result := BcdToDouble(Value.AsBcd^);
  vdtString:
    Result := StrToFloat(Value.AsString^)
else
  raise EConvertError.CreateFmt(SConvertError, [QValueTypeName[ValueType],
    QValueTypeName[vdtFloat]]);
end;
end;

function TQValueHelper.GetAsGuid: TGuid;
begin
if ValueType = vdtGuid then
  Result := Value.AsGuid^
else
  begin
  if ValueType = vdtString then
    begin
    if TryStrToGuid(Value.AsString^, Result) then
      Exit;
    end;
  raise EConvertError.CreateFmt(SConvertError, [QValueTypeName[ValueType],
    QValueTypeName[vdtGuid]]);
  end;
end;

function TQValueHelper.GetAsInt64: Int64;
begin
case ValueType of
  vdtInt64:
    Result := Value.AsInt64;
  vdtInteger:
    Result := Value.AsInteger;
  vdtNull:
    Result := 0;
  vdtBoolean:
    Result := Integer(Value.AsBoolean);
  vdtFloat, vdtDateTime:
    Result := Trunc(Value.AsFloat);
  vdtCurrency:
    Result := Value.AsInt64 div 10000;
  vdtBcd:
    Result := BcdToInt64(Value.AsBcd^);
  vdtString:
    Result := StrToInt64(Value.AsString^)
else
  raise EConvertError.CreateFmt(SConvertError, [QValueTypeName[ValueType],
    QValueTypeName[vdtInt64]]);
end;
end;

function TQValueHelper.GetAsInteger: Integer;
begin
case ValueType of
  vdtInteger:
    Result := Value.AsInteger;
  vdtInt64:
    Result := Value.AsInt64;
  vdtNull:
    Result := 0;
  vdtBoolean:
    Result := Integer(Value.AsBoolean);
  vdtFloat, vdtDateTime:
    Result := Trunc(Value.AsFloat);
  vdtCurrency:
    Result := Value.AsInt64 div 10000;
  vdtBcd:
    Result := BcdToInt64(Value.AsBcd^);
  vdtString:
    Result := StrToInt64(Value.AsString^)
else
  raise EConvertError.CreateFmt(SConvertError, [QValueTypeName[ValueType],
    QValueTypeName[vdtInt64]]);
end;
end;

function TQValueHelper.GetAsInterval: TQInterval;
begin
if ValueType = vdtInterval then
  Result := Value.AsInterval
else
  begin
  if ValueType = vdtString then
    begin
    if Result.TryFromString(Value.AsString^) then
      Exit;
    end;
  raise EConvertError.CreateFmt(SConvertError, [QValueTypeName[ValueType],
    QValueTypeName[vdtInterval]]);
  end;
end;

function TQValueHelper.GetAsStream: TMemoryStream;
begin
if ValueType = vdtStream then
  Result := Value.AsStream
else
  raise EConvertError.CreateFmt(SConvertError, [QValueTypeName[ValueType],
    QValueTypeName[vdtStream]]);
end;

function TQValueHelper.GetAsString: QStringW;
  function DTToStr(Value: TQValueData): QStringW;
  begin
  if Trunc(Value.AsFloat) = 0 then
    Result := FormatDateTime(FormatSettings.LongTimeFormat, Value.AsDateTime)
  else if IsZero(Value.AsFloat - Trunc(Value.AsFloat)) then
    Result := FormatDateTime(FormatSettings.LongDateFormat, Value.AsDateTime)
  else
    Result := FormatDateTime(FormatSettings.LongDateFormat + ' ' +
      FormatSettings.LongTimeFormat, Value.AsDateTime);
  end;
  procedure CatStr(ABuilder: TQStringCatHelperW; const AValue: QStringW);
  var
    ps: PQCharW;
  const
    CharNum1: PWideChar = '1';
    CharNum0: PWideChar = '0';
    Char7: PWideChar = '\b';
    Char9: PWideChar = '\t';
    Char10: PWideChar = '\n';
    Char12: PWideChar = '\f';
    Char13: PWideChar = '\r';
    CharQuoter: PWideChar = '\"';
    CharBackslash: PWideChar = '\\';
    CharCode: PWideChar = '\u00';
  begin
  ps := PQCharW(AValue);
  while ps^ <> #0 do
    begin
    case ps^ of
      #7:
        ABuilder.Cat(Char7, 2);
      #9:
        ABuilder.Cat(Char9, 2);
      #10:
        ABuilder.Cat(Char10, 2);
      #12:
        ABuilder.Cat(Char12, 2);
      #13:
        ABuilder.Cat(Char13, 2);
      '\':
        ABuilder.Cat(CharBackslash, 2);
      '"':
        ABuilder.Cat(CharQuoter, 2);
    else
      begin
      if ps^ < #$1F then
        begin
        ABuilder.Cat(CharCode, 4);
        if ps^ > #$F then
          ABuilder.Cat(CharNum1, 1)
        else
          ABuilder.Cat(CharNum0, 1);
        ABuilder.Cat(HexChar(Ord(ps^) and $0F));
        end
      else
        ABuilder.Cat(ps, 1);
      end;
    end;
    Inc(ps);
    end;
  end;
  procedure ArrToStrHelper(const ABuilder: TQStringCatHelperW;
    const AParent: TQValue);
  var
    I: Integer;
    AItem: PQValue;
  const
    ArrayStart: PWideChar = '[';
    ArrayStop: PWideChar = ']';
    StrStart: PWideChar = '"';
    StrStop: PWideChar = '"';
    StrNull: PWideChar = 'null';
    StrTrue: PWideChar = 'true';
    StrFalse: PWideChar = 'false';
    StrComma: PWideChar = ',';
  begin
  I := 0;
  while I < AParent.Value.Size do
    begin
    AItem := Items[I];
    case AItem.ValueType of
      vdtNull:
        ABuilder.Cat(StrNull, 4);
      vdtBoolean:
        begin
        if AItem.Value.AsBoolean then
          ABuilder.Cat(StrTrue, 4)
        else
          ABuilder.Cat(StrFalse, 5);
        end;
      vdtFloat:
        ABuilder.Cat(Value.AsFloat);
      vdtInteger:
        ABuilder.Cat(Value.AsInteger);
      vdtInt64:
        ABuilder.Cat(Value.AsInt64);
      vdtCurrency:
        ABuilder.Cat(Value.AsCurrency);
      vdtBcd:
        ABuilder.Cat(BcdToStr(Value.AsBcd^));
      vdtGuid:
        ABuilder.Cat(StrStart).Cat(Value.AsGuid^).Cat(StrStop);
      vdtDateTime:
        ABuilder.Cat(StrStart).Cat(DTToStr(Value)).Cat(StrStop);
      vdtInterval:
        ABuilder.Cat(StrStart).Cat(Value.AsInterval.AsString).Cat(StrStop);
      vdtString:
        begin
        ABuilder.Cat(StrStart);
        CatStr(ABuilder, Value.AsString^);
        ABuilder.Cat(StrStop);
        end;
      vdtStream:
        ABuilder.Cat(StrStart).Cat(BinToHex(Value.AsStream.Memory,
          Value.AsStream.Size)).Cat(StrStop);
      vdtArray:
        ArrToStrHelper(ABuilder, AItem^);
    end;
    Inc(I);
    if I < Value.Size then
      ABuilder.Cat(StrComma);
    end;
  ABuilder.Cat(ArrayStop);
  end;
  procedure ArrToStr;
  var
    ABuilder: TQStringCatHelperW;
  begin
  ABuilder := TQStringCatHelperW.Create;
  try
    ArrToStrHelper(ABuilder, Self);
    Result := ABuilder.Value;
  finally
    FreeObject(ABuilder);
  end;
  end;

begin
case ValueType of
  vdtString:
    Result := Value.AsString^;
  vdtNull:
    Result := 'null';
  vdtBoolean:
    Result := BoolToStr(Value.AsBoolean, True);
  vdtFloat:
    Result := FloatToStr(Value.AsFloat);
  vdtInteger:
    Result := IntToStr(Value.AsInteger);
  vdtInt64:
    Result := IntToStr(Value.AsInt64);
  vdtCurrency:
    Result := CurrToStr(Value.AsCurrency);
  vdtBcd:
    Result := BcdToStr(Value.AsBcd^);
  vdtGuid:
    Result := GuidToString(Value.AsGuid^);
  vdtDateTime:
    Result := DTToStr(Value);
  vdtInterval:
    Result := Value.AsInterval.AsString;
  vdtStream:
    Result := BinToHex(Value.AsStream.Memory, Value.AsStream.Size);
  vdtArray:
    ArrToStr;
end;
end;

function TQValueHelper.GetCount: Integer;
begin
if ValueType = vdtArray then
  Result := Value.Size
else
  Result := 0;
end;

function TQValueHelper.GetIsNull: Boolean;
begin
Result := ValueType = vdtNull;
end;

function TQValueHelper.GetItems(AIndex: Integer): PQValue;
begin
if ValueType = vdtArray then
  Result := PQValue(IntPtr(Value.Items) + SizeOf(PQValue) * AIndex)
else
  raise Exception.Create(SValueNotArray);
end;

procedure TQValueHelper.Reset;
  procedure ClearArray;
  var
    I: Integer;
    AItem: PQValue;
  begin
  I := 0;
  AItem := Value.Items;
  while I < Value.Size do
    Items[I].Reset;
  FreeMem(Value.Items);
  end;

begin
case ValueType of
  vdtGuid:
    Dispose(Value.AsGuid);
  vdtString:
    Dispose(Value.AsString);
  vdtStream:
    FreeAndNil(Value.AsStream);
  vdtArray:
    ClearArray;
end;
ValueType := vdtNull;
end;

procedure TQValueHelper.SetAsBcd(const AValue: TBcd);
begin
if ValueType = vdtBcd then
  Value.AsBcd^ := AValue
else if ValueType = vdtString then
  Value.AsString^ := BcdToStr(AValue)
else
  raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtBcd],
    QValueTypeName[ValueType]]);
end;

procedure TQValueHelper.SetAsBoolean(const AValue: Boolean);
begin
case ValueType of
  vdtBoolean:
    Value.AsBoolean := AValue;
  vdtFloat, vdtDateTime:
    Value.AsFloat := Integer(AValue);
  vdtInteger:
    Value.AsInteger := Integer(AValue);
  vdtInt64:
    Value.AsInt64 := Int64(AValue);
  vdtCurrency:
    Value.AsCurrency := Integer(AValue);
  vdtBcd:
    Value.AsBcd^ := Integer(AValue);
  vdtString:
    Value.AsString^ := BoolToStr(AValue, True)
else
  raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtBoolean],
    QValueTypeName[ValueType]]);
end;
end;

procedure TQValueHelper.SetAsCurrency(const AValue: Currency);
begin
case ValueType of
  vdtCurrency:
    Value.AsCurrency := AValue;
  vdtBoolean:
    Value.AsBoolean := AValue <> 0;
  vdtFloat, vdtDateTime:
    Value.AsFloat := AValue;
  vdtInteger:
    Value.AsInteger := Trunc(AValue);
  vdtInt64:
    Value.AsInt64 := Trunc(AValue);
  vdtBcd:
    Value.AsBcd^ := AValue;
  vdtString:
    Value.AsString^ := CurrToStr(AValue)
else
  raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtCurrency],
    QValueTypeName[ValueType]]);
end;
end;

procedure TQValueHelper.SetAsDateTime(const AValue: TDateTime);
begin
case ValueType of
  vdtFloat,vdtDateTime:
    Value.AsFloat := AValue;
  vdtBoolean:
    Value.AsBoolean := IsZero(AValue);
  vdtInteger:
    Value.AsInteger := Trunc(AValue);
  vdtInt64:
    Value.AsInt64 := Trunc(AValue);
  vdtCurrency:
    Value.AsCurrency := AValue;
  vdtBcd:
    Value.AsBcd^ := AValue;
  vdtString:
    Value.AsString^ := DateTimeToStr(AValue)
else
  raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtDateTime],
    QValueTypeName[ValueType]]);
end;
end;

procedure TQValueHelper.SetAsFloat(const AValue: Double);
begin
case ValueType of
  vdtFloat,vdtDateTime:
    Value.AsFloat := AValue;
  vdtBoolean:
    Value.AsBoolean := IsZero(AValue);
  vdtInteger:
    Value.AsInteger := Trunc(AValue);
  vdtInt64:
    Value.AsInt64 := Trunc(AValue);
  vdtCurrency:
    Value.AsCurrency := AValue;
  vdtBcd:
    Value.AsBcd^ := AValue;
  vdtString:
    Value.AsString^ := DateTimeToStr(AValue)
else
  raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtFloat],
    QValueTypeName[ValueType]]);
end;
end;

procedure TQValueHelper.SetAsGuid(const AValue: TGuid);
begin
if ValueType = vdtGuid then
  Value.AsGuid^ := AValue
else if ValueType = vdtString then
  Value.AsString^ := GuidToString(AValue)
else
  raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtGuid],
    QValueTypeName[ValueType]]);
end;

procedure TQValueHelper.SetAsInt64(const AValue: Int64);
begin
case ValueType of
  vdtInt64:
    Value.AsInt64 := AValue;
  vdtInteger:
    Value.AsInteger := AValue;
  vdtBoolean:
    Value.AsBoolean := AValue <> 0;
  vdtFloat, vdtDateTime:
    Value.AsFloat := AValue;
  vdtCurrency:
    Value.AsCurrency := AValue;
  vdtBcd:
    Value.AsBcd^ := AValue;
  vdtString:
    Value.AsString^ := IntToStr(AValue)
else
  raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtInt64],
    QValueTypeName[ValueType]]);
end;
end;

procedure TQValueHelper.SetAsInteger(const AValue: Integer);
begin
case ValueType of
  vdtInteger:
    Value.AsInteger := AValue;
  vdtInt64:
    Value.AsInt64 := AValue;
  vdtBoolean:
    Value.AsBoolean := AValue <> 0;
  vdtFloat, vdtDateTime:
    Value.AsFloat := AValue;
  vdtCurrency:
    Value.AsCurrency := AValue;
  vdtBcd:
    Value.AsBcd^ := AValue;
  vdtString:
    Value.AsString^ := IntToStr(AValue)
else
  raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtInt64],
    QValueTypeName[ValueType]]);
end;
end;

procedure TQValueHelper.SetAsInterval(const AValue: TQInterval);
begin
if ValueType = vdtInterval then
  Value.AsInterval := AValue
else if ValueType = vdtString then
  Value.AsString^ := AValue.AsString
else
  raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtInterval],
    QValueTypeName[ValueType]]);
end;

procedure TQValueHelper.SetAsString(const AValue: QStringW);
  procedure ToStream;
  var
    ABytes: TBytes;
  begin
  HexToBin(AValue, ABytes);
  if Length(ABytes) <> 0 then
    begin
    Value.AsStream.Size := Length(ABytes);
    Value.AsStream.WriteBuffer(ABytes[0], Length(ABytes));
    end
  else if Length(AValue) <> 0 then
    raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtString],
      QValueTypeName[ValueType]])
  else
    Value.AsStream.Size := 0;
  end;
  procedure JsonToArray(AJson: TQJson; AParent: PQValue);
  var
    I: Integer;
    AItem: PQValue;
  begin
  AParent.ArrayNeeded(AJson.Count);
  I := 0;
  while I < AJson.Count do
    begin
    AItem := AParent.Items[I];
    case AJson.DataType of
      jdtUnknown, jdtNull:
        AItem.Reset;
      jdtString:
        begin
        AItem.TypeNeeded(vdtString);
        AItem.Value.AsString^ := AJson[I].AsString;
        end;
      jdtInteger:
        begin
        AItem.TypeNeeded(vdtInteger);
        AItem.Value.AsInteger := AJson[I].AsInteger;
        end;
      jdtFloat:
        begin
        AItem.TypeNeeded(vdtFloat);
        AItem.Value.AsFloat := AJson[I].AsFloat;
        end;
      jdtBoolean:
        begin
        AItem.TypeNeeded(vdtBoolean);
        AItem.Value.AsBoolean := AJson[I].AsBoolean;
        end;
      jdtDateTime:
        begin
        AItem.TypeNeeded(vdtDateTime);
        AItem.Value.AsDateTime := AJson[I].AsDateTime;
        end;
      jdtArray:
        JsonToArray(AJson[I], AItem);
      jdtObject:
        JsonToArray(AJson[I], AItem);
    end;
    Inc(I);
    end;
  end;
  procedure ToArray;
  var
    AJson: TQJson;
  begin
  AJson := TQJson.Create;
  try
    if AJson.TryParse(AValue) and (AJson.DataType = jdtArray) then
      JsonToArray(AJson, @Self)
    else
      raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtString],
        QValueTypeName[ValueType]]);
  finally
    FreeObject(AJson);
  end;
  end;

begin
case ValueType of
  vdtString:
    Value.AsString^ := AValue;
  vdtNull:
    begin
    if StrCmpW(PQCharW(AValue), 'null', True) <> 0 then
      raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtString],
        QValueTypeName[ValueType]]);
    end;
  vdtBoolean:
    Value.AsBoolean := StrToBool(AValue);
  vdtFloat:
    Value.AsFloat := StrToFloat(AValue);
  vdtInteger:
    Value.AsInteger := StrToInt(AValue);
  vdtInt64:
    Value.AsInt64 := StrToInt64(AValue);
  vdtCurrency:
    Value.AsCurrency := StrToCurr(AValue);
  vdtBcd:
    Value.AsBcd^ := StrToBcd(AValue);
  vdtGuid:
    if not TryStrToGuid(AValue, Value.AsGuid^) then
      raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtString],
        QValueTypeName[ValueType]]);
  vdtDateTime:
    if not(TryStrToDateTime(AValue, Value.AsDateTime) or
      ParseDateTime(PQCharW(AValue), Value.AsDateTime) or
      ParseWebTime(PQCharW(AValue), Value.AsDateTime)) then
      raise Exception.CreateFmt(SConvertError, [QValueTypeName[vdtString],
        QValueTypeName[ValueType]]);
  vdtInterval:
    Value.AsInterval.AsString := AValue;
  vdtStream:
    ;
  vdtArray:
    ;
end;
end;
///<summary>确保当前TQValue实例已经按正确的类型初始化</summary>
///<param name="AType">需要的数据类型</param>
procedure TQValueHelper.TypeNeeded(AType: TQValueDataType);
begin
if AType <> ValueType then
  begin
  Reset;
  case AType of
    vdtNull:
      Reset;
    vdtBcd:
      New(Value.AsBcd);
    vdtGuid:
      New(Value.AsGuid);
    vdtString:
      New(Value.AsString);
    vdtStream:
      Value.AsStream := TMemoryStream.Create;
    vdtArray:
      Value.Size := 0;
  end;
  ValueType := AType;
  end;
end;

end.
