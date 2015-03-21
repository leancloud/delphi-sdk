unit qworker;
{$I 'qdac.inc'}

interface

// 该宏决定是否启用QMapSymbols单元来获取函数名称，否则可能取不到真正的名称，而只能是地址
{$IFDEF MSWINDOWS}
{$DEFINE USE_MAP_SYMBOLS}
{$ENDIF}
// 在线程数太多时TQSimpleLock的自旋带来过多的开销，反而不如临界，所以暂时放弃使用
{ .$DEFINE QWORKER_SIMPLE_LOCK }
{
  本源码来自QDAC项目，版权归swish(QQ:109867294)所有。
  (1)、使用许可及限制
  您可以自由复制、分发、修改本源码，但您的修改应该反馈给作者，并允许作者在必要时，
  合并到本项目中以供使用，合并后的源码同样遵循QDAC版权声明限制。
  您的产品的关于中，应包含以下的版本声明:
  本产品使用的JSON解析器来自QDAC项目中的QJSON，版权归作者所有。
  (2)、技术支持
  有技术问题，您可以加入QDAC官方QQ群250530692共同探讨。
  (3)、赞助
  您可以自由使用本源码而不需要支付任何费用。如果您觉得本源码对您有帮助，您可以赞
  助本项目（非强制），以使作者不为生活所迫，有更多的精力为您呈现更好的作品：
  赞助方式：
  支付宝： guansonghuan@sina.com 姓名：管耸寰
  建设银行：
  户名：管耸寰
  账号：4367 4209 4324 0179 731
  开户行：建设银行长春团风储蓄所
}

{ 修订日志
  2015.2.26
  =========
  * 修正了新增功能在 2007 下无法编译的问题（My Spring 报告）
  * 修正了新增功能在 Android / iOS / OSX 下无法编译的问题（麦子仲肥报告）
  2015.2.24
  =========
  + TQJobGroup 新增 Insert 函数用于插入作业到特定位置（芒果提出需求）
  2015.2.9
  =========
  * 修正了移动平台下作业函数为匿名函数的情况下，重复释放匿名函数指针的问题
  2015.2.3
  =========
  * 修正了在使用 FastMM4 并启用 FullDebugInIDE 模式时，退出时出错的问题（浴火重生报告，青春确认）
  * 修正了 OnError 属性忘记发布的问题

  2015.1.29
  =========
  * 修正了 TQSimpleJobs.Clear 如果第一个就满足需要时算法逻辑出错的问题（KEN报告）
  * 修正了在特定情境下无法及时触发重复作业的问题

  2015.1.28
  =========
  * 修正了 Post / At 重复作业时，如果重复间隔 AInterval 参数值小于 0 时陷入无穷重复的问题

  2015.1.26
  =========
  * 修正了 TQJobGroup.Cancel 取消作业时可能造成等待直到超时的问题（麦子仲肥报告）
  2015.1.15
  =========
  + TQJobGroup 加入全局函数和匿名函数的支持

  2015.1.12
  =========
  + 新增函数 PeekJobState 来获取单个作业的状态信息
  + 新增函数 EnumJobStates 来获取所有作业的状态信息

  2015.1.9
  =========
  * 修正了与 2007的兼容问题,Clear(PIntPtr,ACount)改为名ClearJobs

  2014.12.25
  ==========
  * QWorker的Clear(AHandle:IntPtr)函数改为中ClearSingleJob，以解决在早期Delphi中编译问题（星五）

  2014.12.24
  ==========
  + TQWorkers.Clear加入新的重载，允许一次性清理多个作业句柄（测试中，请谨慎使用，lionet建议)

  2014.12.3
  ==========
  * TQJobGroup.Cancel增加是否等待正在运行的作业结束参数，以避免在作业中直接取消
  分组自身的全部作业时死循环的问题（恢弘）

  2014.11.25
  ==========
  * 修正了WaitSignal函数在在特定情况下，处理延迟作业时未能正确触发的问题

  2014.11.24
  ==========
  * 修正了移动平台下，AData为对象时，由于系统自动管理引用计数，造成对象会自动释放的问题（恢弘报告）
  2014.11.13
  ==========
  + TQJobGroup新增FreeAfterDone属性，当设置为True时，所有作业完成后自动释放对象自身（恢弘建议）
  * 修正了TQJobGroup退出时，存在可能死锁的问题
  * 修正了分组作业未全部完成退出时，没有自动释放造成内存泄露的问题（恢弘报告）

  2014.11.11
  ==========
  * 修改作业返回句柄类型为IntPtr，而不是Int64，在32位平台上能稍快一些（音儿小白、恢弘）

  2014.11.8
  ==========
  * 修正了LongtimeJob在返回值为0时，作业对象被Push两遍的问题（音儿小白）
  * 修正了重复作业设置扩展数据时，首次执行完作业后会被释放的问题（音儿小白）
  * 修正了Assign时，忘记增加引用计数的问题
  * For并行在TQWorkers实例下实现一个内联版本直接调用TQForJobs.For对应的版本
  2014.10.30
  ==========
  * 修改条件编译选项，以兼容2007

  2014.10.28
  ==========
  * 加入条件编译选项，以兼容移动平台(恢弘报告)

  2014.10.27
  ===========
  * 修改作业投寄（Post、At、Delay、LongtimeJob等）的返回值为Int64类型的句柄，用来唯一标
  记一项作业，可以在需要时调用Clear(句柄值)来清除相应的作业（感谢恢弘提出需求）
  * TQJobExtData默认实现了更多基本类型的支持（感谢恢弘提出需求）

  2014.10.26
  ==========
  + 新增面向作业的自定义扩展数据类型对象TQJobExtData以便指定作业的释放过程则不受
  jdfFreeAsC1~jdfFreeAsC6的限制，详细说明参考 http://www.qdac.cc/?p=1018 说明
  （感谢恢弘提出需求）

  2014.10.21
  ==========
  * 默认在移动平台不支持QMapSymbols（恢弘报告）
  * 修正在移动平台上设置TStatickThread优先级失败的问题（恢弘报告)

  2014.10.16
  ===========
  * 修正了由于初始化顺序的原因，造成TStaticThread.CheckNeed函数可能在程序启动时出错的问题（青春报告)
  2014.10.14
  ===========
  * 修正了在特定情况下退出由于TStaticThread访问Workers.FSimpleJobs无效地址造成的问题(音儿小白修复)
  2014.10.11
  ==========
  * 修正了TQJobGroup先投寄作业后Prepare/Run时，重复投寄造成出错的问题（音儿小白报告）
  一般推荐正常顺序为Prepare/Add/Run/Wait。
  * 修正了For循环时匿名函数检测错误

  2014.10.8
  =========
  * 修正了TQJobGroup.Count属性无效的问题（五毒报告）
  * 修正了组作业随时添加（非Prepare/Run）时未正确执行的问题（五毒报告）
  * 修正了由于TSystemTimes定义冲突造成函数无法在XE3、XE4上无法编译的问题（宣言报告）

  2014.9.29
  =========
  + EnumWorkerStatus时，加入了工作者最后一次处理作业的时间参数
  * 修正了在特定情况下超时自动解雇工作者机制不生效的问题（音儿小白报告）
  2014.9.26
  =========
  + 加入后台对CPU利用率的检查，在CPU占用率较低时且有需要立即处理的作业时，启动新工作者
  + 加入EnumWorkerStatus函数来枚举各个作业的状态

  2014.9.23
  =========
  * 修正了未达到工作者线程上限，但已创建的工作者都在工作中时可能造成的延迟问题
  2014.9.14
  =========
  + 增加For循环并发作业支持，访问方式为TQForJobs.For(...)
  * 修改TQJobProc/TQJobProcA/TQJobProcG的写法，以便更方便阅读
  * 修正了TQJobGroup.MsgWaitFor时调用Clear方法时忘记传递参数的问题

  2014.9.12
  =========
  * 修正了多个同一时间点并发的重复作业时可能会死掉的问题（简单生活、厦门小叶报告）

  2014.9.10
  =========
  * 修正了At函数计算跨日期时间差时的算法错误(音儿小白报告并修正）

  2014.9.9
  ========
  * 修正了工作者由于IsIdle检查异步造成投寄的多个作业可能被串行执行的问题（音儿小白报告）
  * 修正了同时清除多个作业时，HasJobRunning由于只判断第一个作业在运行就退出造成
  清理时间过长的问题（音儿小白报告）

  2014.9.1
  =========
  * jdfFreeAsRecord改名为jdfFreeAsSimpleRecord，以提示用户这种类型自动释放的记录只
  适用于简单类型，如果是复杂记录类型的释放，请使用jdfFreeAsC1~jdfFreeAsC6，然后由
  用户自己去响应OnCustomFreeData事件处理(感谢qsl和阿木)，参考Demo里复杂类型释放的
  例子。
  2014.8.30
  =========
  * 修正了工作者在有定时作业时未正正确解雇恢复到保留工作者数量的问题（音儿小白报告）

  2014.8.29
  =========
  * 修正了WaitSignal等待超时时，参数类型错误造成等待超时时间不对的错误(厦门小叶报告)
  2014.8.24
  =========
  * 修改了调度算法，解决原来FBusyCount引入的问题

  2014.8.22
  =========
  * 优化了特定高负载环境下，直接投寄作业处理速度（感谢音儿小白)
  * 修正了FMX下Win32/Win64的兼容问题

  2014.8.21
  =========
  * 修正了TQJobGroup没有正确清理自身超时过程的问题（音儿小白报告）
  + 作业附加的Data释放方式新增jdfFreeAsC1~jdfFreeAsC6以便上层自己管理Data成员数据的自动释放
  + 加入OnCustomFreeData事件，用于上层自己处理Data成员的定制释放问题

  2014.8.19
  =========
  * 修正了TQJob.Synchronize由于inline声明造成在2007下无法正确编译的问题
  * 修正了项目在移动平台编译的问题
  2014.8.18
  =========
  * 修正了合并代码造成LongTimeJob投寄数量限制错误的问题(志文报告）
  * 修正了昨天残留的TQJobGroup.Run函数超时设置出错的问题
  + TQJobGroup增加MsgWaitFor函数，以便在主线程中等待而不阻塞主线程(麦子仲肥测试验证)
  + TQJob增加Synchronize函数，实际上公开的是TThread.Synchronize方法(麦子仲肥测试验证)

  2014.8.17
  =========
  * 改进查找空闲线程机制，以避免不必要开销（感谢音儿小白和笑看红尘)
  * 合并代码，以减少重复代码量（感谢音儿小白）
  * 更改了Wait函数接口，AData和AFreeType参数被取消，改为在信号触发时传递相关参数
  * TQJobGroup.AfterDone改为除了在完成时，在中断或超时时仍然触发
  + TQJobGroup.Add函数加入了AFreeType参数
  + TQJobGroup.Run函数加入超时设置，超过指定的时间如果仍未执行完成，则中止后续执行(Bug出没，请注意未彻底搞定)
  + TQJobGroup.Cancel函数用于取消未执行的作业执行

  2014.8.14
  ==========
  * 参考音儿小白的建议，修改Assign函数，同时TQJobHelper的多个属性改为使用同一个函数实现
  * 修正了在Delphi2007上编译的问题(音儿小白报告并提供修改)
  2014.8.12
  ==========
  * 修正了TQJob.Assign函数忘记复制WorkerProcA成员的问题
  2014.8.8
  ==========
  * 修正了在主线程中Clear时，如果有主线程的作业已投寄到主线程消息队列但尚未执行时
  会出现锁死的问题(playwo报告)

  2014.8.7
  ==========
  * 修正了TQJobGroup添加作业时，忘记修改作业完成状态的问题

  2014.8.2
  ==========
  * 修正了在Windows下DLL中使用QWorker时，由于退出时，线程异常中止时，程序无法退
  出的问题(小李飞刀报告，天地弦验证)
  2014.7.29
  ==========
  + 添加了匿名和全局函数重载形式，在XE5以上版本中，可以支持匿名函数做为作业过程
  [注意]匿名函数不应访问局部变量的值
  2014.7.28
  ==========
  * 修正了ComNeeded函数忘记设置初始化完成标志位的问题(天地弦报告)
  2014.7.21
  ==========
  * 修正了Delphi 2007无法编译的问题

  2014.7.17
  =========
  * 修正了在FMX平台上编译时引用Hint的代码
  2014.7.14
  =========
  * 修正了TQJobGroup没有触发AfterDone事件的问题
  * 修改了引发Hint的代码
  2014.7.12
  =========
  + 添加TQJobGroup支持作业分组
  2014.7.4
  ========
  * 修正了与FMX的兼容性问题(恢弘报告)
  + 加入Clear的清除全部作业的重载实现(D10天地弦建议)
  * 支持在作业过程中通过设置IsTerminated属性来安全结束定时及信号作业
  2014.7.3
  =========
  + MakeJobProc来支持全局作业处理函数
  + TQWorkers.Clear函数增加了两个重载函数，实现清理指定信号关联的全部作业(五毒公主ら。建议)
  * 修正了重复作业正在执行时无法清除干净的问题
  2014.6.26
  =========
  * TEvent.WaitFor加入参数，以解决与Delphi2007的兼容性(D10-天地弦报告)
  * 加入HPPEMIT默认链接本单元(麦子仲肥 建议)
  2014.6.23
  =========
  * 修改了Windows下主线程中作业的触发方式，以改善与COM的兼容性（D10-天地弦报告）
  2014.6.21
  =========
  * 加入了对COM的支持，如果需要在作业中使用COM对象，调用Job.Worker.ComNeeded后即可
  正常访问各个COM对象
  2014.6.19
  =========
  * 修正了DoMainThreadWork函数的参数传递顺序错误
  * 为TQWorker加入了ComNeeded函数，以支持COM的初始化，保障作业内COM相关函数调用
  2014.6.17
  =========
  * 信号触发作业时，加入附加数据成员参数，它将被附加到TQJob结构的Data成员，以便
  上层应用能够做必要的标记，默认值为空
  * 作业投寄时加入了附加的参数，决定如何释放附加的数据对象
}
uses
  classes, types, sysutils, SyncObjs
{$IFDEF UNICODE}, Generics.Collections, Rtti{$ENDIF}
{$IFNDEF MSWINDOWS}
    , fmx.Forms, System.Diagnostics
{$ELSE}
{$IFDEF MSWINDOWS}, Windows, Messages, TlHelp32, Activex{$ENDIF}
{$ENDIF}
{$IFDEF POSIX}, Posix.Base, Posix.Unistd, Posix.Pthread{$ENDIF}
    , qstring, qrbtree {, qlog};
{$HPPEMIT '#pragma link "qworker"'}

{ *QWorker是一个后台工作者管理对象，用于管理线程的调度及运行。在QWorker中，最小的
  工作单位被称为作业（Job），作业可以：
  1、在指定的时间点自动按计划执行，类似于计划任务，只是时钟的分辨率可以更高
  2、在得到相应的信号时，自动执行相应的计划任务
  【限制】
  1.时间间隔由于使用0.1ms为基本单位，因此，64位整数最大值为9223372036224000000，
  除以864000000后就可得结果约为10675199116天，因此，QWorker中的作业延迟和定时重复
  间隔最大为10675199116天。
  2、最少工作者数为1个，无论是在单核心还是多核心机器上，这是最低限制。你可以
  设置的最少工作者数必需大于等于1。工作者上限没做实际限制。
  3、长时间作业数量不得超过最多工作者数量的一半，以免影响正常普通作业的响应。因此
  投寄长时间作业时，应检查投寄结果以确认是否投寄成功
  * }
const
  JOB_RUN_ONCE = $000001; // 作业只运行一次
  JOB_IN_MAINTHREAD = $000002; // 作业只能在主线程中运行
  JOB_MAX_WORKERS = $000004; // 尽可能多的开启可能的工作者线程来处理作业，暂不支持
  JOB_LONGTIME = $000008; // 作业需要很长的时间才能完成，以便调度程序减少它对其它作业的影响
  JOB_SIGNAL_WAKEUP = $000010; // 作业根据信号需要唤醒
  JOB_TERMINATED = $000020; // 作业不需要继续进行，可以结束了
  JOB_GROUPED = $000040; // 当前作业是作业组的一员
  JOB_ANONPROC = $000080; // 当前作业过程是匿名函数
  JOB_FREE_OBJECT = $000100; // Data关联的是Object，作业完成或清理时释放
  JOB_FREE_RECORD = $000200; // Data关联的是Record，作业完成或清理时释放
  JOB_FREE_INTERFACE = $000300; // Data关联的是Interface，作业完成时调用_Release
  JOB_FREE_CUSTOM1 = $000400; // Data关联的成员由用户指定的方式1释放
  JOB_FREE_CUSTOM2 = $000500; // Data关联的成员由用户指定的方式2释放
  JOB_FREE_CUSTOM3 = $000600; // Data关联的成员由用户指定的方式3释放
  JOB_FREE_CUSTOM4 = $000700; // Data关联的成员由用户指定的方式4释放
  JOB_FREE_CUSTOM5 = $000800; // Data关联的成员由用户指定的方式5释放
  JOB_FREE_CUSTOM6 = $000900; // Data关联的成员由用户指定的方式6释放
  JOB_DATA_OWNER = $000F00; // 作业是Data成员的所有者

  WORKER_ISBUSY = $0001; // 工作者忙碌
  WORKER_PROCESSLONG = $0002; // 当前处理的一个长时间作业
  WORKER_COM_INITED = $0004; // 工作者已初始化为支持COM的状态(仅限Windows)
  WORKER_LOOKUP = $0008; // 工作者正在查找作业
  WORKER_EXECUTING = $0010; // 工作者正在执行作业
  WORKER_EXECUTED = $0020; // 工作者已经完成作业
  WORKER_FIRING = $0040; // 工作者正在被解雇
  WORKER_RUNNING = $0080; // 工作者线程已经开始运行
  WORKER_CLEANING = $0100; // 工作者线程正在清理作业
  DEFAULT_FIRE_TIMEOUT = 15000;
  INVALID_JOB_DATA = Pointer(-1);
  Q1MillSecond = 10; // 1ms
  Q1Second = 10000; // 1s
  Q1Minute = 600000; // 60s/1min
  Q1Hour = 36000000; // 3600s/60min/1hour
  Q1Day = Int64(864000000); // 1day
{$IFNDEF UNICODE}
  wrIOCompletion = TWaitResult(4);
{$ENDIF}

type
  TQJobs = class;
  TQWorker = class;
  TQWorkers = class;
  TQJobGroup = class;
  TQForJobs = class;
  PQSignal = ^TQSignal;
  PQJob = ^TQJob;
  /// <summary>作业处理回调函数</summary>
  /// <param name="AJob">要处理的作业信息</param>
  TQJobProc = procedure(AJob: PQJob) of object;
  PQJobProc = ^TQJobProc;
  TQJobProcG = procedure(AJob: PQJob);
  TQForJobProc = procedure(ALoopMgr: TQForJobs; AJob: PQJob; AIndex: NativeInt)
    of object;
  PQForJobProc = ^TQForJobProc;
  TQForJobProcG = procedure(ALoopMgr: TQForJobs; AJob: PQJob;
    AIndex: NativeInt);
{$IFDEF UNICODE}
  TQJobProcA = reference to procedure(AJob: PQJob);
  TQForJobProcA = reference to procedure(ALoopMgr: TQForJobs; AJob: PQJob;
    AIndex: NativeInt);
{$ENDIF}
  /// <summary>作业空闲原因，内部使用</summary>
  /// <remarks>
  /// irNoJob : 没有需要处理的作业，此时工作者会进入释放等待状态，如果在等待时间内
  /// 有新作业进来，则工作者会被唤醒，否则超时后会被释放
  /// irTimeout : 工作者已经等待超时，可以被释放
  TWorkerIdleReason = (irNoJob, irTimeout);

  /// <summary>作业结束时如何处理Data成员</summary>
  /// <remarks>
  /// jdoFreeByUser : 用户管理对象的释放
  /// jdoFreeAsObject : 附加的是一个TObject继承的对象，作业完成时会调用FreeObject释放
  /// jdfFreeAsSimpleRecord : 附加的是一个记录（结构体），作业完成时会调用Dispose释放
  /// 注意由于释放时实际上是FreeMem，此结构体不应包含复杂类型，如String/动态数组/Variant等需要
  /// jdtFreeAsInterface : 附加的是一个接口对象，添加时会增加计数，作业完成时会减少计数
  /// jdfFreeAsC1 : 用户自行指定的释放方法1
  /// jdfFreeAsC2 : 用户自行指定的释放方法2
  /// jdfFreeAsC3 : 用户自行指定的释放方法3
  /// jdfFreeAsC4 : 用户自行指定的释放方法4
  /// jdfFreeAsC5 : 自户自行指定的释放方法5
  /// jdfFreeAsC6 : 用户自行指定的释放方法6
  /// </remarks>
  TQJobDataFreeType = (jdfFreeByUser, jdfFreeAsObject, jdfFreeAsSimpleRecord,
    jdfFreeAsInterface, jdfFreeAsC1, jdfFreeAsC2, jdfFreeAsC3, jdfFreeAsC4,
    jdfFreeAsC5, jdfFreeAsC6);

  TQExtFreeEvent = procedure(AData: Pointer) of object;
  TQExtInitEvent = procedure(var AData: Pointer) of Object;
{$IFDEF UNICODE}
  TQExtInitEventA = reference to procedure(var AData: Pointer);
  TQExtFreeEventA = reference to procedure(AData: Pointer);
{$ENDIF}

  TQJobExtData = class
  private
    function GetAsBoolean: Boolean;
    function GetAsDouble: Double;
    function GetAsInteger: Integer;
    function GetAsString: QStringW;
    procedure SetAsBoolean(const Value: Boolean);
    procedure SetAsDouble(const Value: Double);
    procedure SetAsInteger(const Value: Integer);
    procedure SetAsString(const Value: QStringW);
    function GetAsDateTime: TDateTime;
    procedure SetAsDateTime(const Value: TDateTime);
    function GetAsInt64: Int64;
    procedure SetAsInt64(const Value: Int64);
  protected
    FOrigin: Pointer;
    FOnFree: TQExtFreeEvent;
{$IFDEF UNICODE}
    FOnFreeA: TQExtFreeEventA;
{$ENDIF}
    procedure DoFreeAsString(AData: Pointer);
    procedure DoSimpleTypeFree(AData: Pointer);
{$IFNDEF NEXTGEN}
    function GetAsAnsiString: AnsiString;
    procedure SetAsAnsiString(const Value: AnsiString);
    procedure DoFreeAsAnsiString(AData: Pointer);
{$ENDIF}
  public
    constructor Create(AData: Pointer; AOnFree: TQExtFreeEvent); overload;
    constructor Create(AOnInit: TQExtInitEvent;
      AOnFree: TQExtFreeEvent); overload;
{$IFDEF UNICODE}
    constructor Create(AData: Pointer; AOnFree: TQExtFreeEventA); overload;
    constructor Create(AOnInit: TQExtInitEventA;
      AOnFree: TQExtFreeEventA); overload;
{$ENDIF}
    constructor Create(const Value: Int64); overload;
    constructor Create(const Value: Integer); overload;
    constructor Create(const Value: Boolean); overload;
    constructor Create(const Value: Double); overload;
    constructor CreateAsDateTime(const Value: TDateTime); overload;
    constructor Create(const S: QStringW); overload;
{$IFNDEF NEXTGEN}
    constructor Create(const S: AnsiString); overload;
{$ENDIF}
    destructor Destroy; override;
    property Origin: Pointer read FOrigin;
    property AsString: QStringW read GetAsString write SetAsString;
{$IFNDEF NEXTGEN}
    property AsAnsiString: AnsiString read GetAsAnsiString
      write SetAsAnsiString;
{$ENDIF}
    property AsInteger: Integer read GetAsInteger write SetAsInteger;
    property AsInt64: Int64 read GetAsInt64 write SetAsInt64;
    property AsFloat: Double read GetAsDouble write SetAsDouble;
    property AsBoolean: Boolean read GetAsBoolean write SetAsBoolean;
    property AsDateTime: TDateTime read GetAsDateTime write SetAsDateTime;
  end;

  TQJobMethod = record
    case Integer of
      0:
        (Proc: {$IFNDEF NEXTGEN}TQJobProc{$ELSE}Pointer{$ENDIF});
      1:
        (ProcG: TQJobProcG);
      2:
        (ProcA: Pointer);
      3:
        (ForProc: {$IFNDEF NEXTGEN}TQForJobProc{$ELSE}Pointer{$ENDIF});
      4:
        (ForProcG: TQForJobProcG);
      5:
        (ForProcA: Pointer);
      6:
        (Code: Pointer; Data: Pointer);
  end;

  TQJob = record
  private
    function GetAvgTime: Integer; inline;
    function GetElapsedTime: Int64; inline;
    function GetIsTerminated: Boolean; inline;
    function GetFlags(AIndex: Integer): Boolean; inline;
    procedure SetFlags(AIndex: Integer; AValue: Boolean); inline;
    procedure UpdateNextTime;
    procedure SetIsTerminated(const Value: Boolean);
    procedure AfterRun(AUsedTime: Int64);
    function GetFreeType: TQJobDataFreeType; inline;
    function GetIsCustomFree: Boolean; inline;
    function GetIsObjectOwner: Boolean; inline;
    function GetIsRecordOwner: Boolean; inline;
    function GetIsInterfaceOwner: Boolean; inline;
    function GetExtData: TQJobExtData; inline;
  public
    constructor Create(AProc: TQJobProc); overload;
    /// <summary>值拷贝函数</summary>
    /// <remarks>Worker/Next/Source不会复制并会被置空，Owner不会被复制</remarks>
    procedure Assign(const ASource: PQJob);
    /// <summary>重置内容，以便为从队列中弹出做准备</summary>
    procedure Reset; inline;

    /// <summary>公开下线程对象的同步方法，但更推荐投寄异步作业到主线程中处理</summary>
    procedure Synchronize(AMethod: TThreadMethod); overload;{$IFDEF UNICODE}inline;{$ENDIF}
    {$IFDEF UNICODE}
    procedure Synchronize(AProc:TThreadProcedure);overload;inline;
    {$ENDIF}
    /// <summary>平均每次运行时间，单位为0.1ms</summary>
    property AvgTime: Integer read GetAvgTime;
    /// <summmary>本次已运行时间，单位为0.1ms</summary>
    property ElapsedTime: Int64 read GetElapsedTime;
    /// <summary>是否只运行一次，投递作业时自动设置</summary>
    property Runonce: Boolean index JOB_RUN_ONCE read GetFlags;
    /// <summary>是否要求在主线程执行作业，实际效果比Windows的PostMessage相似</summary>
    property InMainThread: Boolean index JOB_IN_MAINTHREAD read GetFlags;
    /// <summary>是否是一个运行时间比较长的作业，用Workers.LongtimeWork设置</summary>
    property IsLongtimeJob: Boolean index JOB_LONGTIME read GetFlags;
    /// <summary>是否是一个信号触发的作业</summary>
    property IsSignalWakeup: Boolean index JOB_SIGNAL_WAKEUP read GetFlags;
    /// <summary>是否是分组作业的成员</summary>
    property IsGrouped: Boolean index JOB_GROUPED read GetFlags;
    /// <summary>是否要求结束当前作业</summary>
    property IsTerminated: Boolean read GetIsTerminated write SetIsTerminated;
    /// <summary>判断作业的Data指向的是一个对象且要求作业完成时自动释放</summary>
    property IsObjectOwner: Boolean read GetIsObjectOwner;
    /// <summary>判断作业的Data指向的是一个记录且要求作业完成时自动释放</summary>
    property IsRecordOwner: Boolean read GetIsRecordOwner;
    /// <summary>判断作业的Data是否是由用户所指定的方法自动释放</summary>
    property IsCustomFree: Boolean read GetIsCustomFree;
    property FreeType: TQJobDataFreeType read GetFreeType;
    /// <summary>判断作业是否拥有Data数据成员
    property IsDataOwner: Boolean index JOB_DATA_OWNER read GetFlags;
    /// <summary>判断作业的Data指向的是一个接口且要求作业完成时自动释放</summary>
    property IsInterfaceOwner: Boolean read GetIsInterfaceOwner;
    /// <summary>判断作业处理过程是否是一个匿名函数</summary>
    property IsAnonWorkerProc: Boolean index JOB_ANONPROC read GetFlags
      write SetFlags;
    /// <summary>扩展的作业处理过程数据</summary>
    property ExtData: TQJobExtData read GetExtData;
  public
    FirstStartTime: Int64; // 作业第一次开始时间
    StartTime: Int64; // 本次作业开始时间,8B
    PushTime: Int64; // 入队时间
    PopTime: Int64; // 出队时间
    NextTime: Int64; // 下一次运行的时间,+8B=16B
    WorkerProc: TQJobMethod; //
    Owner: TQJobs; // 作业所隶属的队列
    Next: PQJob; // 下一个结点
    Worker: TQWorker; // 当前作业工作者
    Runs: Integer; // 已经运行的次数+4B
    MinUsedTime: Cardinal; // 最小运行时间+4B
    TotalUsedTime: Cardinal; // 运行总计花费的时间，TotalUsedTime/Runs可以得出平均执行时间+4B
    MaxUsedTime: Cardinal; // 最大运行时间+4B
    Flags: Integer; // 作业标志位+4B
    Data: Pointer; // 附加数据内容
    case Integer of
      0:
        (SignalId: Integer; // 信号编码
          Source: PQJob; // 源作业地址
          RefCount: PInteger; // 源数据
        );
      1:
        (Interval: Int64; // 运行时间间隔，单位为0.1ms，实际精度受不同操作系统限制+8B
          FirstDelay: Int64; // 首次运行延迟，单位为0.1ms，默认为0
        );
      2: // 分组作业支持
        (Group: Pointer;
        );
  end;

  /// <summary>作业状态，由PeekJobState函数返回</summary>
  TQJobState = record
    Handle: IntPtr; // 作业对象句柄
    Proc: TQJobMethod; // 作业过程
    Flags: Integer; // 标志位
    IsRunning: Boolean; // 是否在运行中，如果为False，则作业处于队列中
    Runs: Integer; // 已经运行的次数
    EscapedTime: Int64; // 已经执行时间
    PushTime: Int64; // 入队时间
    PopTime: Int64; // 出队时间
    AvgTime: Int64; // 平均时间
    TotalTime: Int64; // 总执行时间
    MaxTime: Int64; // 最大执行时间
    MinTime: Int64; // 最小执行时间
    NextTime: Int64; // 重复作业的下次执行时间
  end;

  TQJobStateArray = array of TQJobState;

  /// <summary>工作者记录的辅助函数</summary>
  // TQJobHelper = record helper for TQJob
  //
  // end;

  // 作业队列对象的基类，提供基础的接口封装
  TQJobs = class
  protected
    FOwner: TQWorkers;
    function InternalPush(AJob: PQJob): Boolean; virtual; abstract;
    function InternalPop: PQJob; virtual; abstract;
    function GetCount: Integer; virtual; abstract;
    function GetEmpty: Boolean;
    /// <summary>投寄一个作业</summary>
    /// <param name="AJob">要投寄的作业</param>
    /// <remarks>外部不应尝试直接投寄任务到队列，其由TQWorkers的相应函数内部调用。</remarks>
    function Push(AJob: PQJob): Boolean; virtual;
    /// <summary>弹出一个作业</summary>
    /// <returns>返回当前可以执行的第一个作业</returns>
    function Pop: PQJob; virtual;
    /// <summary>清空所有作业</summary>
    procedure Clear; overload; virtual;
    /// <summary>清空指定的作业</summary>
    function Clear(AProc: TQJobProc; AData: Pointer; AMaxTimes: Integer)
      : Integer; overload; virtual; abstract;
    /// <summary>清空一个对象关联的所有作业</summary>
    function Clear(AObject: Pointer; AMaxTimes: Integer): Integer; overload;
      virtual; abstract;
    /// <summary>根据句柄清除一个作业对象</summary>
    function Clear(AHandle: IntPtr): Boolean; overload; virtual;
    /// <summary>根据句柄列表清除一组作业对象</summary>
    function ClearJobs(AHandes: PIntPtr; ACount: Integer): Integer; overload;
      virtual; abstract;
  public
    constructor Create(AOwner: TQWorkers); overload; virtual;
    destructor Destroy; override;
    /// 不可靠警告：Count和Empty值仅是一个参考，在多线程环境下可能并不保证下一句代码执行时，会一致
    property Empty: Boolean read GetEmpty; // 当前队列是否为空
    property Count: Integer read GetCount; // 当前队列元素数量
  end;
{$IFDEF QWORKER_SIMPLE_LOCK}

  // 一个基于位锁的简单锁定对象，使用原子函数置位
  TQSimpleLock = class
  private
    FFlags: Integer;
  public
    constructor Create;
    procedure Enter; inline;
    procedure Leave; inline;
  end;
{$ELSE}

  TQSimpleLock = TCriticalSection;
{$ENDIF}

  // TQSimpleJobs用于管理简单的异步调用，没有触发时间要求的作业
  TQSimpleJobs = class(TQJobs)
  protected
    FFirst, FLast: PQJob;
    FCount: Integer;
    FLocker: TQSimpleLock;
    function InternalPush(AJob: PQJob): Boolean; override;
    function InternalPop: PQJob; override;
    function GetCount: Integer; override;
    procedure Clear; overload; override;
    function Clear(AObject: Pointer; AMaxTimes: Integer): Integer;
      overload; override;
    function Clear(AProc: TQJobProc; AData: Pointer; AMaxTimes: Integer)
      : Integer; overload; override;
    function Clear(AHandle: IntPtr): Boolean; overload; override;
    function ClearJobs(AHandles: PIntPtr; ACount: Integer): Integer;
      overload; override;
    function PopAll: PQJob;
    procedure Repush(ANewFirst: PQJob);
  public
    constructor Create(AOwner: TQWorkers); override;
    destructor Destroy; override;
  end;

  // TQRepeatJobs用于管理计划型任务，需要在指定的时间点触发
  TQRepeatJobs = class(TQJobs)
  protected
    FItems: TQRBTree;
    FLocker: TCriticalSection;
    FFirstFireTime: Int64;
    function InternalPush(AJob: PQJob): Boolean; override;
    function InternalPop: PQJob; override;
    function DoTimeCompare(P1, P2: Pointer): Integer;
    procedure DoJobDelete(ATree: TQRBTree; ANode: TQRBNode);
    function GetCount: Integer; override;
    procedure Clear; override;
    function Clear(AObject: Pointer; AMaxTimes: Integer): Integer;
      overload; override;
    function Clear(AProc: TQJobProc; AData: Pointer; AMaxTimes: Integer)
      : Integer; overload; override;
    function Clear(AHandle: IntPtr): Boolean; overload; override;
    function ClearJobs(AHandles: PIntPtr; ACount: Integer): Integer;
      overload; override;
    procedure AfterJobRun(AJob: PQJob; AUsedTime: Int64);
  public
    constructor Create(AOwner: TQWorkers); override;
    destructor Destroy; override;
  end;

  { 工作者线程使用单向链表管理，而不是进行排序检索是因为对于工作者数量有限，额外
    的处理反而不会直接最简单的循环直接有效
  }
  TQWorker = class(TThread)
  private
  protected
    FOwner: TQWorkers;
    FEvent: TEvent;
    FTimeout: Cardinal;
    FFlags: Integer;
    FProcessed: Cardinal;
    FActiveJobFlags: Integer;
    FActiveJob: PQJob;
    // 之所以不直接使用FActiveJob的相关方法，是因为保证外部可以线程安全的访问这两个成员
    FActiveJobProc: TQJobMethod;
    FActiveJobData: Pointer;
    FActiveJobSource: PQJob;
    FActiveJobGroup: TQJobGroup;
    FTerminatingJob: PQJob;
    FLastActiveTime: Int64;
    FPending: Boolean; // 已经计划作业
    procedure Execute; override;
    procedure FireInMainThread;
    procedure DoJob(AJob: PQJob);
    function GetIsIdle: Boolean; inline;
    procedure SetFlags(AIndex: Integer; AValue: Boolean); inline;
    function GetFlags(AIndex: Integer): Boolean; inline;
    function WaitSignal(ATimeout: Integer; AByRepeatJob: Boolean)
      : TWaitResult; inline;
  public
    constructor Create(AOwner: TQWorkers); overload;
    destructor Destroy; override;
    procedure ComNeeded(AInitFlags: Cardinal = 0);
    /// <summary>判断当前是否处于长时间作业处理过程中</summary>
    property InLongtimeJob: Boolean index WORKER_PROCESSLONG read GetFlags;
    /// <summary>判断当前是否空闲</summary>
    property IsIdle: Boolean read GetIsIdle;
    /// <summary>判断当前是否忙碌</summary>
    property IsBusy: Boolean index WORKER_ISBUSY read GetFlags;
    property IsLookuping: Boolean index WORKER_LOOKUP read GetFlags;
    property IsExecuting: Boolean index WORKER_EXECUTING read GetFlags;
    property IsExecuted: Boolean index WORKER_EXECUTED read GetFlags;
    property IsFiring: Boolean index WORKER_FIRING read GetFlags;
    property IsRunning: Boolean index WORKER_RUNNING read GetFlags;
    property IsCleaning: Boolean index WORKER_CLEANING read GetFlags;
    /// <summary>判断COM是否已经初始化为支持COM
    property ComInitialized: Boolean index WORKER_COM_INITED read GetFlags;
  end;

  /// <summary>信号的内部定义</summary>
  TQSignal = record
    Id: Integer;
    /// <summary>信号的编码</summary>
    Fired: Integer; // <summary>信号已触发次数</summary>
    Name: QStringW;
    /// <summary>信号的名称</summary>
    First: PQJob;
    /// <summary>首个作业</summary>
  end;

  TWorkerWaitParam = record
    WaitType: Byte;
    Data: Pointer;
    case Integer of
      0:
        (Bound: Pointer); // 按对象清除
      1:
        (WorkerProc: TMethod;);
      2:
        (SourceJob: PQJob);
      3:
        (Group: Pointer);
  end;
  ///<summary>错误来源，可取值包括：
  ///  jesExecute : 执行时出错
  ///  jesFreeData : 释放附加数据时出错
  ///  jesWaitDone : 在等待作业完成时出错
  ///</summary>

  TJobErrorSource = (jesExecute, jesFreeData, jesWaitDone);
  // For并发的索引值类型
  TForLoopIndexType = {$IF RTLVersion>=26}NativeInt{$ELSE}Integer{$IFEND};
  /// <summary>工作者错误通知事件</summary>
  /// <param name="AJob">发生错误的作业对象</param>
  /// <param name="E">发生错误异常对象</param>
  /// <param name="ErrSource">错误来源</param>
  TWorkerErrorNotify = procedure(AJob: PQJob; E: Exception;
    const ErrSource: TJobErrorSource) of object;
  // 自定义数据释放事件
  TQCustomFreeDataEvent = procedure(ASender: TQWorkers;
    AFreeType: TQJobDataFreeType; const AData: Pointer);

  TQWorkerStatusItem = record
    LastActive: Int64;
    Processed: Cardinal;
    ThreadId: TThreadId;
    IsIdle: Boolean;
    ActiveJob: QStringW;
    Stacks: QStringW;
    Timeout: Cardinal;
  end;

  TQWorkerStatus = array of TQWorkerStatusItem;

  /// <summary>工作者管理对象，用来管理工作者和作业</summary>
  TQWorkers = class
  protected
    FWorkers: array of TQWorker;
    FDisableCount: Integer;
    FMinWorkers: Integer;
    FMaxWorkers: Integer;
    FWorkerCount: Integer;
    FBusyCount: Integer;
    FFiringWorkerCount: Integer;
    FFireTimeout: Cardinal;
    FLongTimeWorkers: Integer; // 记录下长时间作业中的工作者，这种任务长时间不释放资源，可能会造成其它任务无法及时响应
    FMaxLongtimeWorkers: Integer; // 允许最多同时执行的长时间任务数，不允许超过MaxWorkers的一半
    FLocker: TCriticalSection;
    FSimpleJobs: TQSimpleJobs;
    FRepeatJobs: TQRepeatJobs;
    FSignalJobs: TQHashTable;
    FMaxSignalId: Integer;
    FTerminating: Boolean;
    FStaticThread: TThread;
    FOnError: TWorkerErrorNotify;
    FOnCustomFreeData: TQCustomFreeDataEvent;
{$IFDEF MSWINDOWS}
    FMainWorker: HWND;
    procedure DoMainThreadWork(var AMsg: TMessage);
{$ENDIF}
    function Popup: PQJob;
    procedure SetMaxWorkers(const Value: Integer);
    function GetEnabled: Boolean;
    procedure SetEnabled(const Value: Boolean);
    procedure SetMinWorkers(const Value: Integer);
    procedure WorkerTimeout(AWorker: TQWorker); inline;
    procedure WorkerTerminate(AWorker: TQWorker);
    procedure FreeJob(AJob: PQJob);
    function LookupIdleWorker(AFromSimple: Boolean): Boolean;
    procedure ClearWorkers;
    procedure SignalWorkDone(AJob: PQJob; AUsedTime: Int64);
    procedure DoJobFree(ATable: TQHashTable; AHash: Cardinal; AData: Pointer);
    function Post(AJob: PQJob): IntPtr; overload;
    procedure SetMaxLongtimeWorkers(const Value: Integer);
    function SignalIdByName(const AName: QStringW): Integer;
    procedure FireSignalJob(ASignal: PQSignal; AData: Pointer;
      AFreeType: TQJobDataFreeType);
    function ClearSignalJobs(ASource: PQJob): Integer;
    procedure WaitSignalJobsDone(AJob: PQJob);
    procedure WaitRunningDone(const AParam: TWorkerWaitParam);
    procedure FreeJobData(AData: Pointer; AFreeType: TQJobDataFreeType);
    procedure DoCustomFreeData(AFreeType: TQJobDataFreeType;
      const AData: Pointer);
    function GetIdleWorkers: Integer; inline;
    function GetBusyCount: Integer; inline;
    function GetOutWorkers: Boolean; inline;
    procedure SetFireTimeout(const Value: Cardinal);
    procedure ValidWorkers; inline;
    procedure NewWorkerNeeded;
    function CreateWorker(ASuspended: Boolean): TQWorker;
    function GetNextRepeatJobTime: Int64; inline;
  public
    constructor Create(AMinWorkers: Integer = 2); overload;
    destructor Destroy; override;
    /// <summary>投寄一个后台立即开始的作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="AData">作业附加的用户数据指针</param>
    /// <param name="ARunInMainThread">作业要求在主线程中执行</param>
    /// <returns>成功投寄返回句柄，否则返回0</returns>
    function Post(AProc: TQJobProc; AData: Pointer;
      ARunInMainThread: Boolean = False;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
    /// <summary>投寄一个后台立即开始的作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="AData">作业附加的用户数据指针</param>
    /// <param name="ARunInMainThread">作业要求在主线程中执行</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>成功投寄返回句柄，否则返回0</returns>
    function Post(AProc: TQJobProcG; AData: Pointer;
      ARunInMainThread: Boolean = False;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
{$IFDEF UNICODE}
    /// <summary>投寄一个后台立即开始的作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="AData">作业附加的用户数据指针</param>
    /// <param name="ARunInMainThread">作业要求在主线程中执行</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>成功投寄返回句柄，否则返回0</returns>
    function Post(AProc: TQJobProcA; AData: Pointer;
      ARunInMainThread: Boolean = False;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
{$ENDIF}
    /// <summary>投寄一个后台定时开始的作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="AInterval">要定时执行的作业时间间隔，单位为0.1ms，如要间隔1秒，则值为10000</param>
    /// <param name="AData">作业附加的用户数据指针</param>
    /// <param name="ARunInMainThread">作业要求在主线程中执行</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>成功投寄返回句柄，否则返回0</returns>
    function Post(AProc: TQJobProc; AInterval: Int64; AData: Pointer;
      ARunInMainThread: Boolean = False;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
    /// <summary>投寄一个后台定时开始的作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="AInterval">要定时执行的作业时间间隔，单位为0.1ms，如要间隔1秒，则值为10000</param>
    /// <param name="AData">作业附加的用户数据指针</param>
    /// <param name="ARunInMainThread">作业要求在主线程中执行</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>成功投寄返回句柄，否则返回0</returns>
    function Post(AProc: TQJobProcG; AInterval: Int64; AData: Pointer;
      ARunInMainThread: Boolean = False;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
{$IFDEF UNICODE}
    /// <summary>投寄一个后台定时开始的作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="AInterval">要定时执行的作业时间间隔，单位为0.1ms，如要间隔1秒，则值为10000</param>
    /// <param name="AData">作业附加的用户数据指针</param>
    /// <param name="ARunInMainThread">作业要求在主线程中执行</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>成功投寄返回句柄，否则返回0</returns>
    function Post(AProc: TQJobProcA; AInterval: Int64; AData: Pointer;
      ARunInMainThread: Boolean = False;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
{$ENDIF}
    /// <summary>投寄一个延迟开始的作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="AInterval">要延迟的时间，单位为0.1ms，如要间隔1秒，则值为10000</param>
    /// <param name="AData">作业附加的用户数据指针</param>
    /// <param name="ARunInMainThread">作业要求在主线程中执行</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>成功投寄返回句柄，否则返回0</returns>
    function Delay(AProc: TQJobProc; ADelay: Int64; AData: Pointer;
      ARunInMainThread: Boolean = False;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
    /// <summary>投寄一个延迟开始的作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="AInterval">要延迟的时间，单位为0.1ms，如要间隔1秒，则值为10000</param>
    /// <param name="AData">作业附加的用户数据指针</param>
    /// <param name="ARunInMainThread">作业要求在主线程中执行</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>成功投寄返回句柄，否则返回0</returns>
    function Delay(AProc: TQJobProcG; ADelay: Int64; AData: Pointer;
      ARunInMainThread: Boolean = False;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
{$IFDEF UNICODE}
    /// <summary>投寄一个延迟开始的作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="AInterval">要延迟的时间，单位为0.1ms，如要间隔1秒，则值为10000</param>
    /// <param name="AData">作业附加的用户数据指针</param>
    /// <param name="ARunInMainThread">作业要求在主线程中执行</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>成功投寄返回句柄，否则返回0</returns>
    function Delay(AProc: TQJobProcA; ADelay: Int64; AData: Pointer;
      ARunInMainThread: Boolean = False;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
{$ENDIF}
    /// <summary>投寄一个等待信号才开始的作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="ASignalId">等待的信号编码，该编码由RegisterSignal函数返回</param>
    /// <param name="ARunInMainThread">作业要求在主线程中执行</param>
    /// <returns>成功投寄返回句柄，否则返回0</returns>
    function Wait(AProc: TQJobProc; ASignalId: Integer;
      ARunInMainThread: Boolean = False): IntPtr; overload;
    /// <summary>投寄一个等待信号才开始的作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="ASignalId">等待的信号编码，该编码由RegisterSignal函数返回</param>
    /// <param name="ARunInMainThread">作业要求在主线程中执行</param>
    /// <returns>成功投寄返回句柄，否则返回0</returns>
    function Wait(AProc: TQJobProcG; ASignalId: Integer;
      ARunInMainThread: Boolean = False): IntPtr; overload;
{$IFDEF UNICODE}
    /// <summary>投寄一个等待信号才开始的作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="ASignalId">等待的信号编码，该编码由RegisterSignal函数返回</param>
    /// <param name="AData">作业附加的用户数据指针</param>
    /// <param name="ARunInMainThread">作业要求在主线程中执行</param>
    /// <returns>成功投寄返回句柄，否则返回0</returns>
    function Wait(AProc: TQJobProcA; ASignalId: Integer;
      ARunInMainThread: Boolean = False): IntPtr; overload;
{$ENDIF}
    /// <summary>投寄一个在指定时间才开始的重复作业</summary>
    /// <param name="AProc">要定时执行的作业过程</param>
    /// <param name="ADelay">第一次执行前先延迟时间</param>
    /// <param name="AInterval">后续作业重复间隔，如果小于等于0，则作业只执行一次，和Delay的效果一致</param>
    /// <param name="ARunInMainThread">是否要求作业在主线程中执行</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>成功投寄返回句柄，失败返回0</returns>
    function At(AProc: TQJobProc; const ADelay, AInterval: Int64;
      AData: Pointer; ARunInMainThread: Boolean = False;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
    /// <summary>投寄一个在指定时间才开始的重复作业</summary>
    /// <param name="AProc">要定时执行的作业过程</param>
    /// <param name="ADelay">第一次执行前先延迟时间</param>
    /// <param name="AInterval">后续作业重复间隔，如果小于等于0，则作业只执行一次，和Delay的效果一致</param>
    /// <param name="ARunInMainThread">是否要求作业在主线程中执行</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>成功投寄返回句柄，失败返回0</returns>
    function At(AProc: TQJobProcG; const ADelay, AInterval: Int64;
      AData: Pointer; ARunInMainThread: Boolean = False;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
{$IFDEF UNICODE}
    /// <summary>投寄一个在指定时间才开始的重复作业</summary>
    /// <param name="AProc">要定时执行的作业过程</param>
    /// <param name="ADelay">第一次执行前先延迟时间</param>
    /// <param name="AInterval">后续作业重复间隔，如果小于等于0，则作业只执行一次，和Delay的效果一致</param>
    /// <param name="ARunInMainThread">是否要求作业在主线程中执行</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>成功投寄返回句柄，失败返回0</returns>
    function At(AProc: TQJobProcA; const ADelay, AInterval: Int64;
      AData: Pointer; ARunInMainThread: Boolean = False;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
{$ENDIF}
    /// <summary>投寄一个在指定时间才开始的重复作业</summary>
    /// <param name="AProc">要定时执行的作业过程</param>
    /// <param name="ATime">执行时间</param>
    /// <param name="AInterval">后续作业重复间隔，如果小于等于0，则作业只执行一次，和Delay的效果一致</param>
    /// <param name="ARunInMainThread">是否要求作业在主线程中执行</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>成功投寄返回句柄，失败返回0</returns>
    function At(AProc: TQJobProc; const ATime: TDateTime;
      const AInterval: Int64; AData: Pointer; ARunInMainThread: Boolean = False;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
    /// <summary>投寄一个在指定时间才开始的重复作业</summary>
    /// <param name="AProc">要定时执行的作业过程</param>
    /// <param name="ATime">执行时间</param>
    /// <param name="AInterval">后续作业重复间隔，如果小于等于0，则作业只执行一次，和Delay的效果一致</param>
    /// <param name="ARunInMainThread">是否要求作业在主线程中执行</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>成功投寄返回句柄，失败返回0</returns>
    function At(AProc: TQJobProcG; const ATime: TDateTime;
      const AInterval: Int64; AData: Pointer; ARunInMainThread: Boolean = False;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
{$IFDEF UNICODE}
    /// <summary>投寄一个在指定时间才开始的重复作业</summary>
    /// <param name="AProc">要定时执行的作业过程</param>
    /// <param name="ATime">执行时间</param>
    /// <param name="AInterval">后续作业重复间隔，如果小于等于0，则作业只执行一次，和Delay的效果一致</param>
    /// <param name="ARunInMainThread">是否要求作业在主线程中执行</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>成功投寄返回句柄，失败返回0</returns>
    function At(AProc: TQJobProcA; const ATime: TDateTime;
      const AInterval: Int64; AData: Pointer; ARunInMainThread: Boolean = False;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
{$ENDIF}
    /// <summary>投寄一个后台长时间执行的作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="AData">作业附加的用户数据指针</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>成功投寄返回True，否则返回False</returns>
    /// <remarks>长时间作业强制在后台线程中执行，而不允许投递到主线程中执行</remarks>
    /// <returns>成功投寄返回句柄，失败返回0</returns>
    function LongtimeJob(AProc: TQJobProc; AData: Pointer;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
    /// <summary>投寄一个后台长时间执行的作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="AData">作业附加的用户数据指针</param>
    /// <returns>成功投寄返回True，否则返回False</returns>
    /// <remarks>长时间作业强制在后台线程中执行，而不允许投递到主线程中执行</remarks>
    /// <returns>成功投寄返回句柄，失败返回0</returns>
    function LongtimeJob(AProc: TQJobProcG; AData: Pointer;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
{$IFDEF UNICODE}
    /// <summary>投寄一个后台长时间执行的作业</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="AData">作业附加的用户数据指针</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>成功投寄返回True，否则返回False</returns>
    /// <remarks>长时间作业强制在后台线程中执行，而不允许投递到主线程中执行</remarks>
    /// <returns>成功投寄返回句柄，失败返回0</returns>
    function LongtimeJob(AProc: TQJobProcA; AData: Pointer;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr; overload;
{$ENDIF}
    /// <summary>清除所有作业</summary>
    procedure Clear; overload;
    /// <summary>清除一个对象相关的所有作业</summary>
    /// <param name="AObject">要释放的作业处理过程关联对象</param>
    /// <param name="AMaxTimes">最多清除的数量，如果<0，则全清</param>
    /// <returns>返回实际清除的作业数量</returns>
    /// <remarks>一个对象如果计划了作业，则在自己释放前应调用本函数以清除关联的作业，
    /// 否则，未完成的作业可能会触发异常。</remarks>
    function Clear(AObject: Pointer; AMaxTimes: Integer = -1): Integer;
      overload;
    /// <summary>清除所有投寄的指定过程作业</summary>
    /// <param name="AProc">要清除的作业执行过程</param>
    /// <param name="AData">要清除的作业附加数据指针地址，如果值为Pointer(-1)，
    /// 则清除所有的相关过程，否则，只清除附加数据地址一致的过程</param>
    /// <param name="AMaxTimes">最多清除的数量，如果<0，则全清</param>
    /// <returns>返回实际清除的作业数量</returns>
    function Clear(AProc: TQJobProc; AData: Pointer; AMaxTimes: Integer = -1)
      : Integer; overload;
    /// <summary>清除指定信号关联的所有作业</summary>
    /// <param name="ASingalName">要清除的信号名称</param>
    /// <returns>返回实际清除的作业数量</returns>
    function Clear(ASignalName: QStringW): Integer; overload;
    /// <summary>清除指定信号关联的所有作业</summary>
    /// <param name="ASingalId">要清除的信号ID</param>
    /// <returns>返回实际清除的作业数量</returns>
    function Clear(ASignalId: Integer): Integer; overload;
    /// <summary>清除指定句柄对应的作业</summary>
    /// <param name="ASingalId">要清除的作业句柄</param>
    /// <returns>返回实际清除的作业数量</returns>
    procedure ClearSingleJob(AHandle: IntPtr); overload;
    /// <summary>清除指定的句柄列表中对应的作业</summary>
    /// <param name="AHandles">由Post/At等投递函数返回的句柄列表</param>
    /// <parma name="ACount">AHandles对应的句柄个数</param>
    /// <returns>返回实际清除的作业数量</returns>
    function ClearJobs(AHandles: PIntPtr; ACount: Integer): Integer; overload;
    /// <summary>触发一个信号</summary>
    /// <param name="AId">信号编码，由RegisterSignal返回</param>
    /// <param name="AData">附加给作业的用户数据指针地址</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <remarks>触发一个信号后，QWorkers会触发所有已注册的信号关联处理过程的执行</remarks>
    procedure Signal(AId: Integer; AData: Pointer = nil;
      AFreeType: TQJobDataFreeType = jdfFreeByUser); overload;
    /// <summary>按名称触发一个信号</summary>
    /// <param name="AName">信号名称</param>
    /// <param name="AData">附加给作业的用户数据指针地址</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <remarks>触发一个信号后，QWorkers会触发所有已注册的信号关联处理过程的执行</remarks>
    procedure Signal(const AName: QStringW; AData: Pointer = nil;
      AFreeType: TQJobDataFreeType = jdfFreeByUser); overload;
    /// <summary>注册一个信号</summary>
    /// <param name="AName">信号名称</param>
    /// <remarks>
    /// 1.重复注册同一名称的信号将返回同一个编码
    /// 2.信号一旦注册，则只有程序退出时才会自动释放
    /// </remarks>
    function RegisterSignal(const AName: QStringW): Integer; // 注册一个信号名称
    /// <summary>启用工作者</summary>
    /// <remarks>和DisableWorkers必需配对使用</remarks>
    procedure EnableWorkers;
    /// <summary>禁用所有工作者</summary>
    /// <remarks>禁用所有工作者将使工作者无法获取到新的作业，直到调用EnableWorkers</remarks>
    procedure DisableWorkers;
    /// <summary>枚举所有工作者状态</summary>
    function EnumWorkerStatus: TQWorkerStatus;
    /// <summary>获取指定作业的状态</summary>
    /// <param name="AHandle">作业对象句柄</param>
    /// <param name="AResult">作业对象状态</param>
    /// <returns>如果指定的作业存在，则返回True，否则，返回False</returns>
    /// <remarks>
    /// 1.对于只执行一次的作业，在执行完后不复存在，所以也会返回false
    /// 2.在FMX平台，如果使用了匿名函数作业过程，必需调用 ClearJobState 函数来执行清理过程，以避免内存泄露。
    /// </remarks>
    function PeekJobState(AHandle: IntPtr; var AResult: TQJobState): Boolean;
    /// <summary>枚举所有的作业状态</summary>
    /// <returns>返回作业状态列表</summary>
    /// <remarks>在FMX平台，如果使用了匿名函数作业过程，必需调用 ClearJobStates 函数来执行清理过程</remarks>
    function EnumJobStates: TQJobStateArray;
    /// <summary>从指定的索引开始并行执行指定的过程到结束索引</summary>
    /// <param name="AStartIndex">起始索引</param>
    /// <param name="AStopIndex">结束索引（含）</param>
    /// <param name="AWorkerProc">要执行的过程</param>
    /// <param name="AMsgWiat">等待作业完成过程中是否响应消息</param>
    /// <param name="AData">附加数据指针</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>返回循环等待结果</returns>
    class function &For(const AStartIndex, AStopIndex: TForLoopIndexType;
      AWorkerProc: TQForJobProc; AMsgWait: Boolean = False;
      AData: Pointer = nil; AFreeType: TQJobDataFreeType = jdfFreeByUser)
      : TWaitResult; overload; static; inline;
{$IFDEF UNICODE}
    /// <summary>从指定的索引开始并行执行指定的过程到结束索引</summary>
    /// <param name="AStartIndex">起始索引</param>
    /// <param name="AStopIndex">结束索引（含）</param>
    /// <param name="AWorkerProc">要执行的过程</param>
    /// <param name="AMsgWiat">等待作业完成过程中是否响应消息</param>
    /// <param name="AData">附加数据指针</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>返回循环等待结果</returns>
    class function &For(const AStartIndex, AStopIndex: TForLoopIndexType;
      AWorkerProc: TQForJobProcA; AMsgWait: Boolean = False;
      AData: Pointer = nil; AFreeType: TQJobDataFreeType = jdfFreeByUser)
      : TWaitResult; overload; static; inline;
{$ENDIF}
    /// <summary>从指定的索引开始并行执行指定的过程到结束索引</summary>
    /// <param name="AStartIndex">起始索引</param>
    /// <param name="AStopIndex">结束索引（含）</param>
    /// <param name="AWorkerProc">要执行的过程</param>
    /// <param name="AMsgWiat">等待作业完成过程中是否响应消息</param>
    /// <param name="AData">附加数据指针</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>返回循环等待结果</returns>
    class function &For(const AStartIndex, AStopIndex: TForLoopIndexType;
      AWorkerProc: TQForJobProcG; AMsgWait: Boolean = False;
      AData: Pointer = nil; AFreeType: TQJobDataFreeType = jdfFreeByUser)
      : TWaitResult; overload; static; inline;

    /// <summary>最大允许工作者数量，不能小于2</summary>
    property MaxWorkers: Integer read FMaxWorkers write SetMaxWorkers;
    /// <summary>最小工作者数量，不能小于2<summary>
    property MinWorkers: Integer read FMinWorkers write SetMinWorkers;
    /// <summary>最大允许的长时间作业工作者数量，等价于允许开始的长时间作业数量</summary>
    property MaxLongtimeWorkers: Integer read FMaxLongtimeWorkers
      write SetMaxLongtimeWorkers;
    /// <summary>是否允许开始作业，如果为false，则投寄的作业都不会被执行，直到恢复为True</summary>
    /// <remarks>Enabled为False时已经运行的作业将仍然运行，它只影响尚未执行的作来</remarks>
    property Enabled: Boolean read GetEnabled write SetEnabled;
    /// <summary>是否正在释放TQWorkers对象自身</summary>
    property Terminating: Boolean read FTerminating;
    /// <summary>当前工作者数量</summary>
    property Workers: Integer read FWorkerCount;
    /// <summary>当前忙碌工作者数量</summary>
    property BusyWorkers: Integer read GetBusyCount;
    /// <summary>当前空闲工作者数量</summary>
    property IdleWorkers: Integer read GetIdleWorkers;
    /// <summary>是否已经到达最大工作者数量</summary>
    property OutOfWorker: Boolean read GetOutWorkers;
    /// <summary>默认解雇工作者的超时时间</summary>
    property FireTimeout: Cardinal read FFireTimeout write SetFireTimeout;
    /// <summary>用户指定的作业的Data对象释放方式</summary>
    property OnCustomFreeData: TQCustomFreeDataEvent read FOnCustomFreeData
      write FOnCustomFreeData;
    /// <summary>下一次重复作业触发时间</summary>
    property NextRepeatJobTime: Int64 read GetNextRepeatJobTime;
    /// <summary>在执行作业出错时触发，以便处理异常</summayr>
    property OnError: TWorkerErrorNotify read FOnError write FOnError;
  end;
{$IFDEF UNICODE}

  TQJobItemList = TList<PQJob>;
{$ELSE}
  TQJobItemList = TList;
{$ENDIF}

  TQJobGroup = class
  protected
    FEvent: TEvent; // 事件，用于等待作业完成
    FLocker: TQSimpleLock;
    FItems: TQJobItemList; // 作业列表
    FPrepareCount: Integer; // 准备计数
    FByOrder: Boolean; // 是否按顺序触发作业，即必需等待上一个作业完成后才执行下一个
    FTimeoutCheck: Boolean; // 是否检查作业超时
    FAfterDone: TNotifyEvent; // 作业完成事件通知
    FWaitResult: TWaitResult;
    FRuns: Integer; // 已经运行的数量
    FPosted: Integer; // 已经提交给QWorker执行的数量
    FTag: Pointer;
    FFreeAfterDone: Boolean;
    function GetCount: Integer;
    procedure DoJobExecuted(AJob: PQJob);
    procedure DoJobsTimeout(AJob: PQJob);
    procedure DoAfterDone;
    function InitGroupJob(AData: Pointer; AInMainThread: Boolean;
      AFreeType: TQJobDataFreeType): PQJob;
    function InternalAddJob(AJob: PQJob): Boolean;
    function InternalInsertJob(AIndex:Integer;AJob:PQJob):Boolean;
  public
    /// <summary>构造函数</summary>
    /// <param name="AByOrder">指定是否是顺序作业，如果为True，则作业会按依次执行</param>
    constructor Create(AByOrder: Boolean = False); overload;
    /// <summary>析构函数</summary>
    destructor Destroy; override;
    /// <summary>取消剩下未执行的作业执行</summary>
    /// <param name="AWaitRunningDone">是否等待正在执行的作业执行完成，默认为True</param>
    /// <remark>如果是在分组的子作业中调用Cancel，AWaitRunningDone一定要设置为False，
    /// 否则，如果要等待分组中正在执行的作业完成，则可以设置为True，否则，可以设置为False</remark>
    procedure Cancel(AWaitRunningDone: Boolean = True);
    /// <summary>要准备添加作业，实际增加内部计数器</summary>
    /// <remarks>Prepare和Run必需匹配使用，否则可能造成作业不会被执行</remarks>
    procedure Prepare;
    /// <summary>减少内部计数器，如果计数器减为0，则开始实际执行作业</summary>
    /// <param name="ATimeout">等待时长，单位为毫秒</param>
    procedure Run(ATimeout: Cardinal = INFINITE);
    /// <summary>插入一个作业过程，如果准备内部计数器为0，则直接执行，否则只添加到列表</summary>
    /// <param name="AIndex">要插入的的位置索引</param>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="AData">附加数据指针</param>
    /// <param name="AInMainThread">作业是否需要在主线程中执行</param>
    /// <param name="AFreeType">AData指定的附加数据指针释放方式</param>
    /// <returns>成功，返回True，失败，返回False</returns>
    /// <remarks>添加到分组中的作业，要么执行完成，要么被取消，不运行通过句柄取消</remarks>
    function Insert(AIndex:Integer;AProc: TQJobProc; AData: Pointer;
      AInMainThread: Boolean = False;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): Boolean; overload;
    /// <summary>插入一个作业过程，如果准备内部计数器为0，则直接执行，否则只添加到列表</summary>
    /// <param name="AIndex">要插入的的位置索引</param>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="AData">附加数据指针</param>
    /// <param name="AInMainThread">作业是否需要在主线程中执行</param>
    /// <param name="AFreeType">AData指定的附加数据指针释放方式</param>
    /// <returns>成功，返回True，失败，返回False</returns>
    /// <remarks>添加到分组中的作业，要么执行完成，要么被取消，不运行通过句柄取消</remarks>
    function Insert(AIndex:Integer;AProc: TQJobProcG; AData: Pointer;
      AInMainThread: Boolean = False;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): Boolean; overload;
    {$IFDEF UNICODE}
    /// <summary>插入一个作业过程，如果准备内部计数器为0，则直接执行，否则只添加到列表</summary>
    /// <param name="AIndex">要插入的的位置索引</param>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="AData">附加数据指针</param>
    /// <param name="AInMainThread">作业是否需要在主线程中执行</param>
    /// <param name="AFreeType">AData指定的附加数据指针释放方式</param>
    /// <returns>成功，返回True，失败，返回False</returns>
    /// <remarks>添加到分组中的作业，要么执行完成，要么被取消，不运行通过句柄取消</remarks>
    function Insert(AIndex:Integer;AProc: TQJobProcA; AData: Pointer;
      AInMainThread: Boolean = False;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): Boolean; overload;
    {$ENDIF}
    /// <summary>添加一个作业过程，如果准备内部计数器为0，则直接执行，否则只添加到列表</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="AData">附加数据指针</param>
    /// <param name="AInMainThread">作业是否需要在主线程中执行</param>
    /// <param name="AFreeType">AData指定的附加数据指针释放方式</param>
    /// <returns>成功，返回True，失败，返回False</returns>
    /// <remarks>添加到分组中的作业，要么执行完成，要么被取消，不运行通过句柄取消</remarks>
    function Add(AProc: TQJobProc; AData: Pointer;
      AInMainThread: Boolean = False;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): Boolean; overload;
    /// <summary>添加一个作业过程，如果准备内部计数器为0，则直接执行，否则只添加到列表</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="AData">附加数据指针</param>
    /// <param name="AInMainThread">作业是否需要在主线程中执行</param>
    /// <param name="AFreeType">AData指定的附加数据指针释放方式</param>
    /// <returns>成功，返回True，失败，返回False</returns>
    /// <remarks>添加到分组中的作业，要么执行完成，要么被取消，不运行通过句柄取消</remarks>
    function Add(AProc: TQJobProcG; AData: Pointer;
      AInMainThread: Boolean = False;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): Boolean; overload;
{$IFDEF UNICODE}
    /// <summary>添加一个作业过程，如果准备内部计数器为0，则直接执行，否则只添加到列表</summary>
    /// <param name="AProc">要执行的作业过程</param>
    /// <param name="AData">附加数据指针</param>
    /// <param name="AInMainThread">作业是否需要在主线程中执行</param>
    /// <param name="AFreeType">AData指定的附加数据指针释放方式</param>
    /// <returns>成功，返回True，失败，返回False</returns>
    /// <remarks>添加到分组中的作业，要么执行完成，要么被取消，不运行通过句柄取消</remarks>
    function Add(AProc: TQJobProcA; AData: Pointer;
      AInMainThread: Boolean = False;
      AFreeType: TQJobDataFreeType = jdfFreeByUser): Boolean; overload;
{$ENDIF}
    /// <summary>等待作业完成</summary>
    /// <param name="ATimeout">最长等待时间，单位为毫秒</param>
    /// <returns>返回等待结果</returns>
    /// <remarks>WaitFor会阻塞当前线程的执行，如果是主线程中调用，建议使用MsgWaitFor
    /// 以保证在主线中的作业能够被执行</remarks>
    function WaitFor(ATimeout: Cardinal = INFINITE): TWaitResult; overload;
    /// <summary>等待作业完成</summary>
    /// <param name="ATimeout">最长等待时间，单位为毫秒</param>
    /// <returns>返回等待结果</returns>
    /// <remarks>如果当前在主线程中执行,MsgWaitFor会检查是否有消息需要处理，而
    /// WaitFor不会，如果在后台线程中执行，会直接调用WaitFor。因此，在主线程中调用
    /// WaitFor会影响主线程中作业的执行，而MsgWaitFor不会
    /// </remarks>
    function MsgWaitFor(ATimeout: Cardinal = INFINITE): TWaitResult;
    /// <summary>未完成的作业数量</summary>
    property Count: Integer read GetCount;
    /// <summary>全部作业执行完成时触发的回调事件</summary>
    property AfterDone: TNotifyEvent read FAfterDone write FAfterDone;
    /// <summary>是否是按顺序执行，只能在构造函数中指定，此处只读</summary>
    property ByOrder: Boolean read FByOrder;
    /// <summary>用户自定的分组附加标签</summary>
    property Tag: Pointer read FTag write FTag;
    /// <summary>是否在作业完成后自动释放自身</summary>
    property FreeAfterDone: Boolean read FFreeAfterDone write FFreeAfterDone;
    /// <summary>已执行完成的作业数量</summary>
    property Runs: Integer read FRuns;
  end;

  TQForJobs = class
  private
    FStartIndex, FStopIndex, FIterator: TForLoopIndexType;
    FBreaked: Integer;
    FEvent: TEvent;
    FWorkerCount: Integer;
    FWorkJob: PQJob;
    procedure DoJob(AJob: PQJob);
    procedure Start;
    function Wait(AMsgWait: Boolean): TWaitResult;
    function GetBreaked: Boolean;
    function GetRuns: Cardinal; inline;
    function GetTotalTime: Cardinal; inline;
    function GetAvgTime: Cardinal; inline;
  public
    constructor Create(const AStartIndex, AStopIndex: TForLoopIndexType;
      AData: Pointer; AFreeType: TQJobDataFreeType); overload;
    destructor Destroy; override;
    /// <summary>从指定的索引开始并行执行指定的过程到结束索引</summary>
    /// <param name="AStartIndex">起始索引</param>
    /// <param name="AStopIndex">结束索引（含）</param>
    /// <param name="AWorkerProc">要执行的过程</param>
    /// <param name="AMsgWiat">等待作业完成过程中是否响应消息</param>
    /// <param name="AData">附加数据指针</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>返回循环等待结果</returns>
    class function &For(const AStartIndex, AStopIndex: TForLoopIndexType;
      AWorkerProc: TQForJobProc; AMsgWait: Boolean = False;
      AData: Pointer = nil; AFreeType: TQJobDataFreeType = jdfFreeByUser)
      : TWaitResult; overload; static;
{$IFDEF UNICODE}
    /// <summary>从指定的索引开始并行执行指定的过程到结束索引</summary>
    /// <param name="AStartIndex">起始索引</param>
    /// <param name="AStopIndex">结束索引（含）</param>
    /// <param name="AWorkerProc">要执行的过程</param>
    /// <param name="AMsgWiat">等待作业完成过程中是否响应消息</param>
    /// <param name="AData">附加数据指针</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>返回循环等待结果</returns>
    class function &For(const AStartIndex, AStopIndex: TForLoopIndexType;
      AWorkerProc: TQForJobProcA; AMsgWait: Boolean = False;
      AData: Pointer = nil; AFreeType: TQJobDataFreeType = jdfFreeByUser)
      : TWaitResult; overload; static;
{$ENDIF}
    /// <summary>从指定的索引开始并行执行指定的过程到结束索引</summary>
    /// <param name="AStartIndex">起始索引</param>
    /// <param name="AStopIndex">结束索引（含）</param>
    /// <param name="AWorkerProc">要执行的过程</param>
    /// <param name="AMsgWiat">等待作业完成过程中是否响应消息</param>
    /// <param name="AData">附加数据指针</param>
    /// <param name="AFreeType">附加数据指针释放方式</param>
    /// <returns>返回循环等待结果</returns>
    class function &For(const AStartIndex, AStopIndex: TForLoopIndexType;
      AWorkerProc: TQForJobProcG; AMsgWait: Boolean = False;
      AData: Pointer = nil; AFreeType: TQJobDataFreeType = jdfFreeByUser)
      : TWaitResult; overload; static;
    /// <summary>中断循环的执行</summary>
    procedure BreakIt;
    /// <summary>起始索引</summary>
    property StartIndex: TForLoopIndexType read FStartIndex;
    /// <summary>结束索引</summary>
    property StopIndex: TForLoopIndexType read FStopIndex;
    /// <summary>已中断</summary>
    property Breaked: Boolean read GetBreaked;
    /// <summary>已运行次数<summary>
    property Runs: Cardinal read GetRuns;
    /// <summary>总运行时间，精度为0.1ms</summary>
    property TotalTime: Cardinal read GetTotalTime;
    /// <summary>平均每次调用用时，精度为0.1ms</summary>
    property AvgTime: Cardinal read GetAvgTime;
  end;

type
  TGetThreadStackInfoFunction = function(AThread: TThread): QStringW;
  TMainThreadProc=procedure (AData:Pointer) of object;
  TMainThreadProcG=procedure (AData:Pointer);
  /// <summary>将全局的作业处理函数转换为TQJobProc类型，以便正常调度使用</summary>
  /// <param name="AProc">全局的作业处理函数</param>
  /// <returns>返回新的TQJobProc实例</returns>
function MakeJobProc(const AProc: TQJobProcG): TQJobProc; overload;
// 获取系统中CPU的核心数量
function GetCPUCount: Integer;
// 获取当前系统的时间戳，最高可精确到0.1ms，但实际受操作系统限制
function GetTimestamp: Int64;
// 设置线程运行的CPU
procedure SetThreadCPU(AHandle: THandle; ACpuNo: Integer);
// 原子锁定与运算
function AtomicAnd(var Dest: Integer; const AMask: Integer): Integer;
// 原子锁定或运算
function AtomicOr(var Dest: Integer; const AMask: Integer): Integer;
/// <summary>获取作业对象池中缓存的作业对象数量</summary>
function JobPoolCount: NativeInt;
/// <summary>打印作业池中缓存的作业对象信息</summary>
function JobPoolPrint: QStringW;
/// <summary>清除指定作业状态的状态信息</summary>
/// <param name="AState">作业状态</param>
procedure ClearJobState(var AState: TQJobState); inline;
/// <summary>清除指定作业状态数组的状态信息</summary>
/// <param name="AStates">作业状态数组</param>
procedure ClearJobStates(var AStates: TQJobStateArray);
/// <summary>在主线程中执行指定的函数</summary>
/// <param name="AProc">要执行的函数</param>
/// <param name="AData">附加参数</param>
procedure RunInMainThread(AProc:TMainThreadProc;AData:Pointer);overload;
/// <summary>在主线程中执行指定的函数</summary>
/// <param name="AProc">要执行的函数</param>
/// <param name="AData">附加参数</param>
procedure RunInMainThread(AProc:TMainThreadProcG;AData:Pointer);overload;
{$IFDEF UNICODE}
/// <summary>在主线程中执行指定的函数</summary>
/// <param name="AProc">要执行的函数</param>
procedure RunInMainThread(AProc:TThreadProcedure);overload;
{$ENDIF}
var
  Workers: TQWorkers;
  GetThreadStackInfo: TGetThreadStackInfoFunction;

implementation

{$IFDEF USE_MAP_SYMBOLS}

uses qmapsymbols;
{$ENDIF}

resourcestring
  SNotSupportNow = '当前尚未支持功能 %s';
  STooFewWorkers = '指定的最小工作者数量太少(必需大于等于1)。';
  STooManyLongtimeWorker = '不能允许太多长时间作业线程(最多允许工作者一半)。';
  SBadWaitDoneParam = '未知的等待正在执行作业完成方式:%d';
  SUnsupportPlatform = '%s 当前在本平台不受支持。';

type
{$IFDEF MSWINDOWS}
  TGetTickCount64 = function: Int64;
  TGetSystemTimes = function(var lpIdleTime, lpKernelTime,
    lpUserTime: TFileTime): BOOL; stdcall;
{$ENDIF MSWINDOWS}

  TJobPool = class
  protected
    FFirst: PQJob;
    FCount: Integer;
    FSize: Integer;
    FLocker: TQSimpleLock;
  public
    constructor Create(AMaxSize: Integer); overload;
    destructor Destroy; override;
    procedure Push(AJob: PQJob);
    function Pop: PQJob;
    property Count: Integer read FCount;
    property Size: Integer read FSize write FSize;
  end;
{$IF RTLVersion<24}

  TSystemTimes = record
    IdleTime, UserTime, KernelTime, NiceTime: UInt64;
  end;
{$IFEND <XE3}

  TStaticThread = class(TThread)
  protected
    FEvent: TEvent;
    FLastTimes: {$IF RTLVersion>=24}TThread.{$IFEND >=XE5}TSystemTimes;
    procedure Execute; override;
  public
    constructor Create; overload;
    destructor Destroy; override;
    procedure CheckNeeded;
  end;

  TRunInMainThreadHelper=class
    FProc:TMainThreadProc;
    FData:Pointer;
    procedure Execute;
  end;
var
  JobPool: TJobPool;
  _CPUCount: Integer;
{$IFDEF MSWINDOWS}
  GetTickCount64: TGetTickCount64;
  WinGetSystemTimes: TGetSystemTimes;
  _PerfFreq: Int64;
{$ELSE}
  _Watch: TStopWatch;
{$ENDIF}
{$IFDEF __BORLANDC}
procedure FreeAsCDelete(AData: Pointer); external;
procedure FreeAsCDeleteArray(AData: Pointer); external;
{$ENDIF}

procedure ThreadYield;
begin
{$IFDEF MSWINDOWS}
SwitchToThread;
{$ELSE}
TThread.Yield;
{$ENDIF}
end;

procedure ProcessAppMessage;
{$IFDEF MSWINDOWS}
var
  AMsg: MSG;
{$ENDIF}
begin
{$IFDEF MSWINDOWS}
while PeekMessage(AMsg, 0, 0, 0, PM_REMOVE) do
  begin
  TranslateMessage(AMsg);
  DispatchMessage(AMsg);
  end;
{$ELSE}
Application.ProcessMessages;
{$ENDIF}
end;

function MsgWaitForEvent(AEvent: TEvent; ATimeout: Cardinal): TWaitResult;
var
  T: Cardinal;
{$IFDEF MSWINDOWS}
  AHandles: array [0 .. 0] of THandle;
  rc: DWORD;
{$ENDIF}
begin
if GetCurrentThreadId <> MainThreadId then
  Result := AEvent.WaitFor(ATimeout)
else
  begin
{$IFDEF MSWINDOWS}
  Result := wrTimeout;
  AHandles[0] := AEvent.Handle;
  repeat
    T := GetTickCount;
    rc := MsgWaitForMultipleObjects(1, AHandles[0], False, ATimeout,
      QS_ALLINPUT);
    if rc = WAIT_OBJECT_0 + 1 then
      begin
      ProcessAppMessage;
      T := GetTickCount - T;
      if ATimeout > T then
        Dec(ATimeout, T)
      else
        begin
        Result := wrTimeout;
        Break;
        end;
      end
    else
      begin
      case rc of
        WAIT_ABANDONED:
          Result := wrAbandoned;
        WAIT_OBJECT_0:
          Result := wrSignaled;
        WAIT_TIMEOUT:
          Result := wrTimeout;
        WAIT_FAILED:
          Result := wrError;
        WAIT_IO_COMPLETION:
          Result := wrIOCompletion;
      end;
      Break;
      end;
  until False;
{$ELSE}
  repeat
    // 每隔10毫秒检查一下是否有消息需要处理，有则处理，无则进入下一个等待
    T := GetTimestamp;
    Result := AEvent.WaitFor(10);
    if Result = wrTimeout then
      begin
      T := (GetTimestamp - T) div 10;
      ProcessAppMessage;
      if ATimeout > T then
        Dec(ATimeout, T)
      else
        Break;
      end
    else
      Break;
  until False;
{$ENDIF}
  end;
end;

procedure ClearJobState(var AState: TQJobState);
begin
if IsFMXApp then
  begin
  if (AState.Flags and JOB_ANONPROC) <> 0 then
    begin
    IUnknown(AState.Proc.ProcA)._Release;
    end;
  AState.Proc.Code := nil;
  AState.Proc.Data := nil;
  end;
end;

procedure ClearJobStates(var AStates: TQJobStateArray);
var
  I: Integer;
begin
for I := 0 to High(AStates) do
  ClearJobState(AStates[I]);
SetLength(AStates, 0);
end;

procedure JobInitialize(AJob: PQJob; AData: Pointer;
  AFreeType: TQJobDataFreeType; ARunOnce, ARunInMainThread: Boolean); inline;
begin
AJob.Data := AData;
if AData <> nil then
  begin
  AJob.Flags := AJob.Flags or (Integer(AFreeType) shl 8);
  if AFreeType = jdfFreeAsInterface then
    IUnknown(AData)._AddRef
{$IFDEF NEXTGEN}
    // 移动平台下AData的计数需要增加，以避免自动释放
  else if AFreeType = jdfFreeAsObject then
    TObject(AData).__ObjAddRef;
{$ENDIF}
  ;
  end;
AJob.SetFlags(JOB_RUN_ONCE, ARunOnce);
AJob.SetFlags(JOB_IN_MAINTHREAD, ARunInMainThread);
end;

// 位与，返回原值
function AtomicAnd(var Dest: Integer; const AMask: Integer): Integer; inline;
var
  I: Integer;
begin
repeat
  Result := Dest;
  I := Result and AMask;
until AtomicCmpExchange(Dest, I, Result) = Result;
end;

// 位或，返回原值
function AtomicOr(var Dest: Integer; const AMask: Integer): Integer; inline;
var
  I: Integer;
begin
repeat
  Result := Dest;
  I := Result or AMask;
until AtomicCmpExchange(Dest, I, Result) = Result;
end;

procedure SetThreadCPU(AHandle: THandle; ACpuNo: Integer);
begin
{$IFDEF MSWINDOWS}
SetThreadIdealProcessor(AHandle, ACpuNo);
{$ELSE}
// Linux/Andriod/iOS暂时忽略,XE6未引入sched_setaffinity定义,啥时引入了再加以支持
{$ENDIF}
end;

// 返回值的时间精度为100ns，即0.1ms
function GetTimestamp: Int64;
begin
{$IFDEF MSWINDOWS}
if _PerfFreq > 0 then
  begin
  QueryPerformanceCounter(Result);
  Result := Result * 10000 div _PerfFreq;
  end
else if Assigned(GetTickCount64) then
  Result := GetTickCount64 * 10000
else
  Result := GetTickCount* 10000;
{$ELSE}
Result := _Watch.Elapsed.Ticks div 1000;
{$ENDIF}
end;

function GetCPUCount: Integer;
{$IFDEF MSWINDOWS}
var
  si: SYSTEM_INFO;
{$ENDIF}
begin
if _CPUCount = 0 then
  begin
{$IFDEF MSWINDOWS}
  GetSystemInfo(si);
  Result := si.dwNumberOfProcessors;
{$ELSE}// Linux,MacOS,iOS,Andriod{POSIX}
{$IFDEF POSIX}
  Result := sysconf(_SC_NPROCESSORS_ONLN);
{$ELSE}// 不认识的操作系统，CPU数默认为1
  Result := 1;
{$ENDIF !POSIX}
{$ENDIF !MSWINDOWS}
  end
else
  Result := _CPUCount;
end;

function MakeJobProc(const AProc: TQJobProcG): TQJobProc;
begin
TMethod(Result).Data := nil;
TMethod(Result).Code := @AProc;
end;

function SameWorkerProc(const P1: TQJobMethod; P2: TQJobProc): Boolean; inline;
begin
Result := (P1.Code = TMethod(P2).Code) and (P1.Data = TMethod(P2).Data);
end;
{ TQJob }

procedure TQJob.AfterRun(AUsedTime: Int64);
begin
Inc(Runs);
if AUsedTime > 0 then
  begin
  Inc(TotalUsedTime, AUsedTime);
  if MinUsedTime = 0 then
    MinUsedTime := AUsedTime
  else if MinUsedTime > AUsedTime then
    MinUsedTime := AUsedTime;
  if MaxUsedTime = 0 then
    MaxUsedTime := AUsedTime
  else if MaxUsedTime < AUsedTime then
    MaxUsedTime := AUsedTime;
  end;
end;

procedure TQJob.Assign(const ASource: PQJob);
begin
Self := ASource^;
{$IFDEF UNICODE}
if IsAnonWorkerProc then
  IUnknown(Self.WorkerProc.ProcA)._AddRef;
{$ENDIF}
// 下面三个成员不拷贝
Worker := nil;
Next := nil;
Source := nil;
end;

constructor TQJob.Create(AProc: TQJobProc);
begin
{$IFDEF NEXTGEN}
PQJobProc(@WorkerProc)^ := AProc;
{$ELSE}
WorkerProc.Proc := AProc;
{$ENDIF}
SetFlags(JOB_RUN_ONCE, True);
end;

function TQJob.GetAvgTime: Integer;
begin
if Runs > 0 then
  Result := TotalUsedTime div Cardinal(Runs)
else
  Result := 0;
end;

function TQJob.GetIsCustomFree: Boolean;
begin
Result := FreeType in [jdfFreeAsC1 .. jdfFreeAsC6];
end;

function TQJob.GetIsInterfaceOwner: Boolean;
begin
Result := (FreeType = jdfFreeAsInterface);
end;

function TQJob.GetIsObjectOwner: Boolean;
begin
Result := (FreeType = jdfFreeAsObject);
end;

function TQJob.GetIsRecordOwner: Boolean;
begin
Result := (FreeType = jdfFreeAsSimpleRecord);
end;

function TQJob.GetIsTerminated: Boolean;
begin
if Assigned(Worker) then
  Result := Workers.Terminating or Worker.Terminated or
    ((Flags and JOB_TERMINATED) <> 0) or (Worker.FTerminatingJob = @Self)
else
  Result := (Flags and JOB_TERMINATED) <> 0;
end;

function TQJob.GetElapsedTime: Int64;
begin
Result := GetTimestamp - StartTime;
end;

function TQJob.GetExtData: TQJobExtData;
begin
Result := Data;
end;

function TQJob.GetFlags(AIndex: Integer): Boolean;
begin
Result := (Flags and AIndex) <> 0;
end;

function TQJob.GetFreeType: TQJobDataFreeType;
begin
Result := TQJobDataFreeType((Flags shr 8) and $0F);
end;

procedure TQJob.Reset;
begin
FillChar(Self, SizeOf(TQJob), 0);
end;

procedure TQJob.SetFlags(AIndex: Integer; AValue: Boolean);
begin
if AValue then
  Flags := (Flags or AIndex)
else
  Flags := (Flags and (not AIndex));
end;

procedure TQJob.SetIsTerminated(const Value: Boolean);
begin
SetFlags(JOB_TERMINATED, Value);
end;
{$IFDEF UNICODE}
procedure TQJob.Synchronize(AProc: TThreadProcedure);
begin
if GetCurrentThreadId=MainThreadId then
  AProc
else
  Worker.Synchronize(AProc);
end;
{$ENDIF}
procedure TQJob.Synchronize(AMethod: TThreadMethod);
begin
if GetCurrentThreadId=MainThreadId then
  AMethod
else
  Worker.Synchronize(AMethod);
end;

procedure TQJob.UpdateNextTime;
begin
if (Runs = 0) and (FirstDelay <> 0) then
  NextTime := PushTime + FirstDelay
else if Interval <> 0 then
  begin
  if NextTime = 0 then
    NextTime := GetTimestamp + Interval
  else
    Inc(NextTime, Interval);
  end
else
  NextTime := GetTimestamp;
end;

{ TQSimpleJobs }

function TQSimpleJobs.Clear(AObject: Pointer; AMaxTimes: Integer): Integer;
var
  AFirst, AJob, APrior, ANext: PQJob;
begin
// 先将SimpleJobs所有的异步作业清空，以防止被弹出执行
AJob := PopAll;
Result := 0;
APrior := nil;
AFirst := nil;
while (AJob <> nil) and (AMaxTimes <> 0) do
  begin
  ANext := AJob.Next;
  if AJob.WorkerProc.Data = AObject then
    begin
    if APrior <> nil then
      APrior.Next := ANext
    else // 首个
      AFirst := ANext;
    AJob.Next := nil;
    FOwner.FreeJob(AJob);
    Dec(AMaxTimes);
    Inc(Result);
    end
  else
    begin
    if AFirst = nil then
      AFirst := AJob;
    APrior := AJob;
    end;
  AJob := ANext;
  end;
Repush(AFirst);
end;

function TQSimpleJobs.Clear(AProc: TQJobProc; AData: Pointer;
  AMaxTimes: Integer): Integer;
var
  AFirst, AJob, APrior, ANext: PQJob;
begin
AJob := PopAll;
Result := 0;
APrior := nil;
AFirst := nil;
while (AJob <> nil) and (AMaxTimes <> 0) do
  begin
  ANext := AJob.Next;
  if SameWorkerProc(AJob.WorkerProc, AProc) and
    ((AJob.Data = AData) or (AData = INVALID_JOB_DATA)) then
    begin
    if APrior <> nil then
      APrior.Next := ANext
    else // 首个
      AFirst := ANext;
    AJob.Next := nil;
    FOwner.FreeJob(AJob);
    Dec(AMaxTimes);
    Inc(Result);
    end
  else
    begin
    if AFirst = nil then
      AFirst := AJob;
    APrior := AJob;
    end;
  AJob := ANext;
  end;
Repush(AFirst);
end;

procedure TQSimpleJobs.Clear;
var
  AFirst: PQJob;
begin
FLocker.Enter;
AFirst := FFirst;
FFirst := nil;
FLast := nil;
FCount := 0;
FLocker.Leave;
FOwner.FreeJob(AFirst);
end;

function TQSimpleJobs.Clear(AHandle: IntPtr): Boolean;
var
  AFirst, AJob, APrior, ANext: PQJob;
begin
AJob := PopAll;
Result := False;
APrior := nil;
AFirst := nil;
while AJob <> nil do
  begin
  ANext := AJob.Next;
  if Int64(AJob) = AHandle then
    begin
    if APrior <> nil then
      APrior.Next := ANext
    else // 首个
      AFirst := ANext;
    AJob.Next := nil;
    FOwner.FreeJob(AJob);
    Result := True;
    Break;
    end
  else
    begin
    if AFirst = nil then
      AFirst := AJob;
    APrior := AJob;
    end;
  AJob := ANext;
  end;
Repush(AFirst);
end;

constructor TQSimpleJobs.Create(AOwner: TQWorkers);
begin
inherited Create(AOwner);
FLocker := TQSimpleLock.Create;
end;

destructor TQSimpleJobs.Destroy;
begin
inherited;
FreeObject(FLocker);
end;

function TQSimpleJobs.GetCount: Integer;
begin
Result := FCount;
end;

function TQSimpleJobs.InternalPop: PQJob;
begin
FLocker.Enter;
Result := FFirst;
if Result <> nil then
  begin
  FFirst := Result.Next;
  if FFirst = nil then
    FLast := nil;
  Dec(FCount);
  end;
FLocker.Leave;
end;

function TQSimpleJobs.InternalPush(AJob: PQJob): Boolean;
begin
FLocker.Enter;
if FLast = nil then
  FFirst := AJob
else
  FLast.Next := AJob;
FLast := AJob;
Inc(FCount);
FLocker.Leave;
Result := True;
end;

function TQSimpleJobs.PopAll: PQJob;
begin
FLocker.Enter;
Result := FFirst;
FFirst := nil;
FLast := nil;
FCount := 0;
FLocker.Leave;
end;

procedure TQSimpleJobs.Repush(ANewFirst: PQJob);
var
  ALast: PQJob;
  ACount: Integer;
begin
if ANewFirst <> nil then
  begin
  ALast := ANewFirst;
  ACount := 0;
  while ALast.Next <> nil do
    begin
    ALast := ALast.Next;
    Inc(ACount);
    end;
  FLocker.Enter;
  ALast.Next := FFirst;
  FFirst := ANewFirst;
  if FLast = nil then
    FLast := ALast;
  Inc(FCount, ACount);
  FLocker.Leave;
  end;
end;

function TQSimpleJobs.ClearJobs(AHandles: PIntPtr; ACount: Integer): Integer;
var
  AFirst, AJob, APrior, ANext: PQJob;
  // AHandleEof: PIntPtr;
  function Accept(AJob: PQJob): Boolean;
  var
    p: PIntPtr;
  begin
  p := AHandles;
  Result := False;
  while IntPtr(p) < IntPtr(AHandles) do
    begin
    if (IntPtr(p^) and (not $03)) = IntPtr(AJob) then
      begin
      p^ := 0; // 置空
      Result := True;
      Exit;
      end;
    Inc(p);
    end;
  end;

begin
AJob := PopAll;
Result := 0;
APrior := nil;
AFirst := nil;
// AHandleEof := AHandles;
// Inc(AHandleEof, ACount);
while AJob <> nil do
  begin
  ANext := AJob.Next;
  if Accept(AJob) then
    begin
    if APrior <> nil then
      APrior.Next := ANext;
    AJob.Next := nil;
    FOwner.FreeJob(AJob);
    Inc(Result);
    Break;
    end
  else
    begin
    if AFirst = nil then
      AFirst := AJob;
    APrior := AJob;
    end;
  AJob := ANext;
  end;
Repush(AFirst);
end;

{ TQJobs }

procedure TQJobs.Clear;
var
  AItem: PQJob;
begin
repeat
  AItem := Pop;
  if AItem <> nil then
    FOwner.FreeJob(AItem)
  else
    Break;
until 1 > 2;
end;

function TQJobs.Clear(AHandle: IntPtr): Boolean;
begin
Result := ClearJobs(@AHandle, 1) = 1;
end;

constructor TQJobs.Create(AOwner: TQWorkers);
begin
inherited Create;
FOwner := AOwner;
end;

destructor TQJobs.Destroy;
begin
Clear;
inherited;
end;

function TQJobs.GetEmpty: Boolean;
begin
Result := (Count = 0);
end;

function TQJobs.Pop: PQJob;
begin
Result := InternalPop;
if Result <> nil then
  begin
  Result.PopTime := GetTimestamp;
  Result.Next := nil;
  end;
end;

function TQJobs.Push(AJob: PQJob): Boolean;
begin
//Assert(AJob.WorkerProc.Code<>nil);
AJob.Owner := Self;
AJob.PushTime := GetTimestamp;
Result := InternalPush(AJob);
if not Result then
  begin
  AJob.Next := nil;
  FOwner.FreeJob(AJob);
  end;
end;

{ TQRepeatJobs }

procedure TQRepeatJobs.Clear;
begin
FLocker.Enter;
try
  FItems.Clear;
finally
  FLocker.Leave;
end;
end;

function TQRepeatJobs.Clear(AObject: Pointer; AMaxTimes: Integer): Integer;
var
  ANode, ANext: TQRBNode;
  APriorJob, AJob, ANextJob: PQJob;
  ACanDelete: Boolean;
begin
// 现在清空重复的计划作业
Result := 0;
FLocker.Enter;
try
  ANode := FItems.First;
  while (ANode <> nil) and (AMaxTimes <> 0) do
    begin
    ANext := ANode.Next;
    AJob := ANode.Data;
    ACanDelete := True;
    APriorJob := nil;
    while AJob <> nil do
      begin
      ANextJob := AJob.Next;
      if AJob.WorkerProc.Data = AObject then
        begin
        if ANode.Data = AJob then
          ANode.Data := AJob.Next;
        if Assigned(APriorJob) then
          APriorJob.Next := AJob.Next;
        AJob.Next := nil;
        FOwner.FreeJob(AJob);
        Dec(AMaxTimes);
        Inc(Result);
        end
      else
        begin
        ACanDelete := False;
        APriorJob := AJob;
        end;
      AJob := ANextJob;
      end;
    if ACanDelete then
      FItems.Delete(ANode);
    ANode := ANext;
    end;
  if FItems.Count > 0 then
    FFirstFireTime := PQJob(FItems.First.Data).NextTime
  else
    FFirstFireTime := 0;
finally
  FLocker.Leave;
end;
end;

procedure TQRepeatJobs.AfterJobRun(AJob: PQJob; AUsedTime: Int64);
var
  ANode: TQRBNode;
  function UpdateSource: Boolean;
  var
    ATemp, APrior: PQJob;
  begin
  Result := False;
  ATemp := ANode.Data;
  APrior := nil;
  while ATemp <> nil do
    begin
    if ATemp = AJob.Source then
      begin
      if AJob.IsTerminated then
        begin
        if APrior <> nil then
          APrior.Next := ATemp.Next
        else
          ANode.Data := ATemp.Next;
        ATemp.Next := nil;
        FOwner.FreeJob(ATemp);
        if ANode.Data = nil then
          FItems.Delete(ANode);
        end
      else
        ATemp.AfterRun(AUsedTime);
      Result := True;
      Break;
      end;
    APrior := ATemp;
    ATemp := ATemp.Next;
    end;
  end;

begin
FLocker.Enter;
try
  ANode := FItems.Find(AJob);
  if ANode <> nil then
    begin
    if UpdateSource then
      Exit;
    end;
  ANode := FItems.First;
  while ANode <> nil do
    begin
    if UpdateSource then
      Break;
    ANode := ANode.Next;
    end;
finally
  FLocker.Leave;
end;
end;

function TQRepeatJobs.Clear(AProc: TQJobProc; AData: Pointer;
  AMaxTimes: Integer): Integer;
var
  AJob, APrior, ANext: PQJob;
  ANode, ANextNode: TQRBNode;
begin
Result := 0;
FLocker.Enter;
try
  ANode := FItems.First;
  while (ANode <> nil) and (AMaxTimes <> 0) do
    begin
    AJob := ANode.Data;
    APrior := nil;
    repeat
      if SameWorkerProc(AJob.WorkerProc, AProc) and
        ((AData = INVALID_JOB_DATA) or (AData = AJob.Data)) then
        begin
        ANext := AJob.Next;
        if APrior = nil then
          ANode.Data := ANext
        else
          APrior.Next := AJob.Next;
        AJob.Next := nil;
        FOwner.FreeJob(AJob);
        AJob := ANext;
        Dec(AMaxTimes);
        Inc(Result);
        end
      else
        begin
        APrior := AJob;
        AJob := AJob.Next
        end;
    until AJob = nil;
    if ANode.Data = nil then
      begin
      ANextNode := ANode.Next;
      FItems.Delete(ANode);
      ANode := ANextNode;
      end
    else
      ANode := ANode.Next;
    end;
  if FItems.Count > 0 then
    FFirstFireTime := PQJob(FItems.First.Data).NextTime
  else
    FFirstFireTime := 0;
finally
  FLocker.Leave;
end;
end;

constructor TQRepeatJobs.Create(AOwner: TQWorkers);
begin
inherited;
FItems := TQRBTree.Create(DoTimeCompare);
FItems.OnDelete := DoJobDelete;
FLocker := TCriticalSection.Create;
end;

destructor TQRepeatJobs.Destroy;
begin
inherited;
FreeObject(FItems);
FreeObject(FLocker);
end;

procedure TQRepeatJobs.DoJobDelete(ATree: TQRBTree; ANode: TQRBNode);
begin
FOwner.FreeJob(ANode.Data);
end;

function TQRepeatJobs.DoTimeCompare(P1, P2: Pointer): Integer;
begin
Result := PQJob(P1).NextTime - PQJob(P2).NextTime;
end;

function TQRepeatJobs.GetCount: Integer;
begin
Result := FItems.Count;
end;

function TQRepeatJobs.InternalPop: PQJob;
var
  ANode: TQRBNode;
  ATick: Int64;
  AJob: PQJob;
begin
Result := nil;
if FItems.Count = 0 then
  Exit;
FLocker.Enter;
try
  if FItems.Count > 0 then
    begin
    ATick := GetTimestamp;
    ANode := FItems.First;
    AJob := ANode.Data;
    // OutputDebugString(PWideChar('Result.NextTime='+IntToStr(AJob.NextTime)+',Current='+IntToStr(ATick)+',Delta='+IntToStr(AJob.NextTime-ATick)));
    if AJob.NextTime <= ATick then
      begin
      if AJob.Next <> nil then // 如果没有更多需要执行的作业，则删除结点，否则指向下一个
        ANode.Data := AJob.Next
      else
        begin
        ANode.Data := nil;
        FItems.Delete(ANode);
        ANode := FItems.First;
        if ANode <> nil then
          FFirstFireTime := PQJob(ANode.Data).NextTime
        else // 没有计划作业了，不需要了
          FFirstFireTime := 0;
        end;
      if AJob.Runonce then
        Result := AJob
      else
        begin
        AJob.Next := nil;
        Inc(AJob.NextTime, AJob.Interval);
        Result := JobPool.Pop;
        Result.Assign(AJob);
        Result.Source := AJob;
        // 重新插入作业
        ANode := FItems.Find(AJob);
        if ANode = nil then
          begin
          FItems.Insert(AJob);
          FFirstFireTime := PQJob(FItems.First.Data).NextTime;
          end
        else // 如果已经存在同一时刻的作业，则自己挂接到其它作业头部
          begin
          AJob.Next := PQJob(ANode.Data);
          ANode.Data := AJob; // 首个作业改为自己
          end;
        end;
      end;
    end
  else
    FFirstFireTime := 0;
finally
  FLocker.Leave;
end;
end;

function TQRepeatJobs.InternalPush(AJob: PQJob): Boolean;
var
  ANode: TQRBNode;
begin
// 计算作业的下次执行时间
AJob.UpdateNextTime;
FLocker.Enter;
try
  ANode := FItems.Find(AJob);
  if ANode = nil then
    begin
    FItems.Insert(AJob);
    FFirstFireTime := PQJob(FItems.First.Data).NextTime;
    end
  else // 如果已经存在同一时刻的作业，则自己挂接到其它作业头部
    begin
    AJob.Next := PQJob(ANode.Data);
    ANode.Data := AJob; // 首个作业改为自己
    end;
  Result := True;
finally
  FLocker.Leave;
end;
end;

function TQRepeatJobs.Clear(AHandle: IntPtr): Boolean;
var
  ANode, ANext: TQRBNode;
  APriorJob, AJob, ANextJob: PQJob;
  ACanDelete: Boolean;
begin
Result := False;
AHandle := AHandle and (not $03);
FLocker.Enter;
try
  ANode := FItems.First;
  while ANode <> nil do
    begin
    ANext := ANode.Next;
    AJob := ANode.Data;
    ACanDelete := True;
    APriorJob := nil;
    while AJob <> nil do
      begin
      ANextJob := AJob.Next;
      if Int64(AJob) = AHandle then
        begin
        if ANode.Data = AJob then
          ANode.Data := AJob.Next;
        if Assigned(APriorJob) then
          APriorJob.Next := AJob.Next;
        AJob.Next := nil;
        FOwner.FreeJob(AJob);
        Result := True;
        Break;
        end
      else
        begin
        ACanDelete := False;
        APriorJob := AJob;
        end;
      AJob := ANextJob;
      end;
    if ACanDelete then
      FItems.Delete(ANode);
    ANode := ANext;
    end;
  if FItems.Count > 0 then
    FFirstFireTime := PQJob(FItems.First.Data).NextTime
  else
    FFirstFireTime := 0;
finally
  FLocker.Leave;
end;
end;

function TQRepeatJobs.ClearJobs(AHandles: PIntPtr; ACount: Integer): Integer;
var
  ANode, ANext: TQRBNode;
  APriorJob, AJob, ANextJob: PQJob;
  ACanDelete: Boolean;
  function Accept(AJob: PQJob): Boolean;
  var
    p: PIntPtr;
  begin
  p := AHandles;
  Result := False;
  while IntPtr(p) < IntPtr(AHandles) do
    begin
    if (IntPtr(p^) and (not $03)) = IntPtr(AJob) then
      begin
      p^ := 0;
      Result := True;
      Exit;
      end;
    Inc(p);
    end;
  end;

begin
Result := 0;
FLocker.Enter;
try
  ANode := FItems.First;
  while ANode <> nil do
    begin
    ANext := ANode.Next;
    AJob := ANode.Data;
    ACanDelete := True;
    APriorJob := nil;
    while AJob <> nil do
      begin
      ANextJob := AJob.Next;
      if Accept(AJob) then
        begin
        if ANode.Data = AJob then
          ANode.Data := AJob.Next;
        if Assigned(APriorJob) then
          APriorJob.Next := AJob.Next;
        AJob.Next := nil;
        FOwner.FreeJob(AJob);
        Inc(Result);
        end
      else
        begin
        ACanDelete := False;
        APriorJob := AJob;
        end;
      AJob := ANextJob;
      end;
    if ACanDelete then
      FItems.Delete(ANode);
    ANode := ANext;
    end;
  if FItems.Count > 0 then
    FFirstFireTime := PQJob(FItems.First.Data).NextTime
  else
    FFirstFireTime := 0;
finally
  FLocker.Leave;
end;
end;

{ TQWorker }

procedure TQWorker.ComNeeded(AInitFlags: Cardinal);
begin
{$IFDEF MSWINDOWS}
if not ComInitialized then
  begin
  if AInitFlags = 0 then
    CoInitialize(nil)
  else
    CoInitializeEx(nil, AInitFlags);
  FFlags := FFlags or WORKER_COM_INITED;
  end;
{$ENDIF MSWINDOWS}
end;

constructor TQWorker.Create(AOwner: TQWorkers);
begin
inherited Create(True);
FOwner := AOwner;
FTimeout := 1000;
FreeOnTerminate := True;
FEvent := TEvent.Create(nil, False, False, '');
end;

destructor TQWorker.Destroy;
begin
FreeObject(FEvent);
inherited;
end;

procedure TQWorker.DoJob(AJob: PQJob);
begin
{$IFDEF UNICODE}
if AJob.IsAnonWorkerProc then
  TQJobProcA(AJob.WorkerProc.ProcA)(AJob)
else
{$ENDIF}
  begin
  if AJob.WorkerProc.Data <> nil then
{$IFDEF NEXTGEN}
    PQJobProc(@AJob.WorkerProc)^(AJob)
{$ELSE}
    AJob.WorkerProc.Proc(AJob)
{$ENDIF}
  else
    AJob.WorkerProc.ProcG(AJob);
  end;
end;

function TQWorker.WaitSignal(ATimeout: Integer; AByRepeatJob: Boolean)
  : TWaitResult;
var
  T: Int64;
begin
if ATimeout > 1 then
  begin
  T := GetTimestamp;
  Result := FEvent.WaitFor(ATimeout);
  T := GetTimestamp - T;
  if Result = wrTimeout then
    begin
    Inc(FTimeout, T div 10);
    if AByRepeatJob then
      Result := wrSignaled;
    end;
  end
else
  Result := wrSignaled;
end;

procedure TQWorker.Execute;
var
  wr: TWaitResult;
  ARandomDelay:Cardinal;
{$IFDEF MSWINDOWS}
  SyncEvent: TEvent;
{$ENDIF}
begin
{$IFDEF MSWINDOWS}
SyncEvent := TEvent.Create(nil, False, False, '');
{$IFDEF UNICODE}
NameThreadForDebugging('QWorker');
{$ENDIF}
{$ENDIF}
try
  SetFlags(WORKER_RUNNING, True);
  FLastActiveTime := GetTimestamp;
  ARandomDelay:=Random(FOwner.FFireTimeout shr 1);
  while not(Terminated or FOwner.FTerminating) do
    begin
    SetFlags(WORKER_CLEANING, False);
    if FOwner.Enabled then
      begin
      if FOwner.FSimpleJobs.FFirst <> nil then
        wr := WaitSignal(0, False)
      else if (FOwner.FRepeatJobs.FFirstFireTime <> 0) then
        wr := WaitSignal((FOwner.FRepeatJobs.FFirstFireTime - GetTimestamp)
          div 10, True)
      else
        wr := WaitSignal(FOwner.FFireTimeout, False);
      end
    else
      wr := WaitSignal(FOwner.FFireTimeout, False);
    if Terminated or FOwner.FTerminating then
      Break;
    if wr = wrSignaled then
      begin
      if FOwner.FTerminating then
        Break;
      SetFlags(WORKER_LOOKUP or WORKER_ISBUSY, True);
      FPending := False;
      if (FOwner.Workers - AtomicIncrement(FOwner.FBusyCount) = 0) and
        (FOwner.Workers < FOwner.MaxWorkers) then
        FOwner.NewWorkerNeeded;
      repeat
        FActiveJob := FOwner.Popup;
        if FActiveJob <> nil then
          begin
          FTimeout := 0;
          FLastActiveTime := FActiveJob.PopTime;
          FActiveJob.Worker := Self;
          FActiveJobProc := FActiveJob.WorkerProc;
          // {$IFDEF NEXTGEN} PQJobProc(@FActiveJob.WorkerProc)^
          // {$ELSE} FActiveJob.WorkerProc.Proc {$ENDIF};
          // 为Clear(AObject)准备判断，以避免FActiveJob线程不安全
          FActiveJobData := FActiveJob.Data;
          if FActiveJob.IsSignalWakeup then
            FActiveJobSource := FActiveJob.Source
          else
            FActiveJobSource := nil;
          if FActiveJob.IsGrouped then
            FActiveJobGroup := FActiveJob.Group
          else
            FActiveJobGroup := nil;
          FActiveJobFlags := FActiveJob.Flags;
          if FActiveJob.StartTime = 0 then
            begin
            FActiveJob.StartTime := FLastActiveTime;
            FActiveJob.FirstStartTime := FActiveJob.StartTime;
            end
          else
            FActiveJob.StartTime := FLastActiveTime;
          try
            FFlags := (FFlags or WORKER_EXECUTING) and (not WORKER_LOOKUP);
            if FActiveJob.InMainThread then
{$IFDEF MSWINDOWS}
              begin
              if PostMessage(FOwner.FMainWorker, WM_APP, WPARAM(FActiveJob),
                LPARAM(SyncEvent)) then
                SyncEvent.WaitFor(INFINITE);
              end
{$ELSE}
              Synchronize(Self, FireInMainThread)
{$ENDIF}
            else
              DoJob(FActiveJob);
          except
            on E: Exception do
              if Assigned(FOwner.FOnError) then
                FOwner.FOnError(FActiveJob, E, jesExecute);
          end;
          Inc(FProcessed);
          SetFlags(WORKER_CLEANING, True);
          if not FActiveJob.Runonce then
            begin
            FOwner.FRepeatJobs.AfterJobRun(FActiveJob,
              GetTimestamp - FActiveJob.StartTime);
            FActiveJob.Data := nil;
            end
          else
            begin
            if FActiveJob.IsSignalWakeup then
              FOwner.SignalWorkDone(FActiveJob,
                GetTimestamp - FActiveJob.StartTime)
            else if FActiveJob.IsLongtimeJob then
              AtomicDecrement(FOwner.FLongTimeWorkers)
            else if FActiveJob.IsGrouped then
              FActiveJobGroup.DoJobExecuted(FActiveJob);
            FActiveJob.Worker := nil;
            end;
          FOwner.FreeJob(FActiveJob);
          FActiveJobProc.Code := nil;
          FActiveJobProc.Data := nil;
          FActiveJobSource := nil;
          FActiveJobFlags := 0;
          FActiveJobGroup := nil;
          FTerminatingJob := nil;
          FFlags := FFlags and (not WORKER_EXECUTING);
          end
        else
          FFlags := FFlags and (not WORKER_LOOKUP);
      until (FActiveJob = nil) or Terminated or FOwner.FTerminating or
        (not FOwner.Enabled);
      SetFlags(WORKER_ISBUSY, False);
      AtomicDecrement(FOwner.FBusyCount);
      ThreadYield;
      end
    else
      begin
      if (FTimeout >= FOwner.FireTimeout+ARandomDelay) then // 加一个随机的2秒延迟，以避免同时释放
        FOwner.WorkerTimeout(Self);
      end;
    end;
finally
  SetFlags(WORKER_RUNNING, False);
{$IFDEF MSWINDOWS}
  FreeObject(SyncEvent);
  if ComInitialized then
    CoUninitialize;
{$ENDIF}
  FOwner.WorkerTerminate(Self);
end;
end;

procedure TQWorker.FireInMainThread;
begin
DoJob(FActiveJob);
end;

function TQWorker.GetFlags(AIndex: Integer): Boolean;
begin
Result := ((FFlags and AIndex) <> 0);
end;

function TQWorker.GetIsIdle: Boolean;
begin
Result := not IsBusy;
end;

procedure TQWorker.SetFlags(AIndex: Integer; AValue: Boolean);
begin
if AValue then
  FFlags := FFlags or AIndex
else
  FFlags := FFlags and (not AIndex);
end;

{ TQWorkers }

function TQWorkers.Post(AJob: PQJob): IntPtr;
begin
Result := 0;
if (not FTerminating) and (Assigned(AJob.WorkerProc.Proc)
{$IFDEF UNICODE} or Assigned(AJob.WorkerProc.ProcA){$ENDIF}) then
  begin
  if AJob.Runonce and (AJob.FirstDelay = 0) then
    begin
    if FSimpleJobs.Push(AJob) then
      begin
      Result := IntPtr(AJob);
      LookupIdleWorker(True);
      end;
    end
  else if FRepeatJobs.Push(AJob) then
    begin
    Result := IntPtr(AJob) + $01;
    LookupIdleWorker(False);
    end;
  end
else
  begin
  AJob.Next := nil;
  FreeJob(AJob);
  end;
end;

function TQWorkers.Post(AProc: TQJobProc; AData: Pointer;
  ARunInMainThread: Boolean; AFreeType: TQJobDataFreeType): IntPtr;
var
  AJob: PQJob;
begin
AJob := JobPool.Pop;
JobInitialize(AJob, AData, AFreeType, True, ARunInMainThread);
{$IFDEF NEXTGEN}
PQJobProc(@AJob.WorkerProc)^ := AProc;
{$ELSE}
AJob.WorkerProc.Proc := AProc;
{$ENDIF}
Result := Post(AJob);
end;

function TQWorkers.Post(AProc: TQJobProc; AInterval: Int64; AData: Pointer;
  ARunInMainThread: Boolean; AFreeType: TQJobDataFreeType): IntPtr;
var
  AJob: PQJob;
begin
AJob := JobPool.Pop;
JobInitialize(AJob, AData, AFreeType, AInterval <= 0, ARunInMainThread);
AJob.Interval := AInterval;
{$IFDEF NEXTGEN}
PQJobProc(@AJob.WorkerProc)^ := AProc;
{$ELSE}
AJob.WorkerProc.Proc := AProc;
{$ENDIF}
Result := Post(AJob);
end;

function TQWorkers.Post(AProc: TQJobProcG; AData: Pointer;
  ARunInMainThread: Boolean; AFreeType: TQJobDataFreeType): IntPtr;
begin
Result := Post(MakeJobProc(AProc), AData, ARunInMainThread, AFreeType);
end;

{$IFDEF UNICODE}

function TQWorkers.Post(AProc: TQJobProcA; AData: Pointer;
  ARunInMainThread: Boolean; AFreeType: TQJobDataFreeType): IntPtr;
var
  AJob: PQJob;
begin
AJob := JobPool.Pop;
JobInitialize(AJob, AData, AFreeType, True, ARunInMainThread);
TQJobProcA(AJob.WorkerProc.ProcA) := AProc;
AJob.IsAnonWorkerProc := True;
Result := Post(AJob);
end;
{$ENDIF}

function TQWorkers.Clear(AObject: Pointer; AMaxTimes: Integer): Integer;
var
  ACleared: Integer;
  AWaitParam: TWorkerWaitParam;
  function ClearSignalJobs: Integer;
  var
    I: Integer;
    AJob, ANext, APrior: PQJob;
    AList: PQHashList;
    ASignal: PQSignal;
  begin
  Result := 0;
  FLocker.Enter;
  try
    for I := 0 to FSignalJobs.BucketCount - 1 do
      begin
      AList := FSignalJobs.Buckets[I];
      if AList <> nil then
        begin
        ASignal := AList.Data;
        if ASignal.First <> nil then
          begin
          AJob := ASignal.First;
          APrior := nil;
          while (AJob <> nil) and (AMaxTimes <> 0) do
            begin
            ANext := AJob.Next;
            if AJob.WorkerProc.Data = AObject then
              begin
              if ASignal.First = AJob then
                ASignal.First := ANext;
              if Assigned(APrior) then
                APrior.Next := ANext;
              AJob.Next := nil;
              FreeJob(AJob);
              Dec(AMaxTimes);
              Inc(Result);
              end
            else
              APrior := AJob;
            AJob := ANext;
            end;
          if AMaxTimes = 0 then
            Break;
          end;
        end;
      end;
  finally
    FLocker.Leave;
  end;
  end;

begin
Result := 0;
if Self <> nil then
  begin
  ACleared := FSimpleJobs.Clear(AObject, AMaxTimes);
  Inc(Result, ACleared);
  Dec(AMaxTimes, ACleared);
  if AMaxTimes <> 0 then
    begin
    ACleared := FRepeatJobs.Clear(AObject, AMaxTimes);
    Inc(Result, ACleared);
    Dec(AMaxTimes, ACleared);
    if AMaxTimes <> 0 then
      begin
      ACleared := ClearSignalJobs;
      Inc(Result, ACleared);
      if AMaxTimes <> 0 then
        begin
        AWaitParam.WaitType := 0;
        AWaitParam.Bound := AObject;
        WaitRunningDone(AWaitParam);
        end;
      end;
    end;
  end;
end;

function TQWorkers.At(AProc: TQJobProc; const ADelay, AInterval: Int64;
  AData: Pointer; ARunInMainThread: Boolean;
  AFreeType: TQJobDataFreeType): IntPtr;
var
  AJob: PQJob;
begin
AJob := JobPool.Pop;
JobInitialize(AJob, AData, AFreeType, AInterval <= 0, ARunInMainThread);
{$IFDEF NEXTGEN}
PQJobProc(@AJob.WorkerProc)^ := AProc;
{$ELSE}
AJob.WorkerProc.Proc := AProc;
{$ENDIF}
AJob.Interval := AInterval;
AJob.FirstDelay := ADelay;
Result := Post(AJob);
end;

function TQWorkers.At(AProc: TQJobProc; const ATime: TDateTime;
  const AInterval: Int64; AData: Pointer; ARunInMainThread: Boolean;
  AFreeType: TQJobDataFreeType): IntPtr;
var
  AJob: PQJob;
  ADelay: Int64;
  ANow, ATemp: TDateTime;
begin
AJob := JobPool.Pop;
JobInitialize(AJob, AData, AFreeType, AInterval <= 0, ARunInMainThread);
{$IFDEF NEXTGEN}
PQJobProc(@AJob.WorkerProc)^ := AProc;
{$ELSE}
AJob.WorkerProc.Proc := AProc;
{$ENDIF}
AJob.Interval := AInterval;
// ATime我们只要时间部分，日期忽略
ANow := Now;
ANow := ANow - Trunc(ANow);
ATemp := ATime - Trunc(ATime);
if ANow > ATemp then // 好吧，今天的点已经过了，算明天
  ADelay := Trunc(((1 - ANow) + ATemp) * Q1Day) // 延迟的时间，单位为0.1ms
else
  ADelay := Trunc((ATemp - ANow) * Q1Day);
AJob.FirstDelay := ADelay;
Result := Post(AJob);
end;

class function TQWorkers.&For(const AStartIndex, AStopIndex: TForLoopIndexType;
  AWorkerProc: TQForJobProc; AMsgWait: Boolean; AData: Pointer;
  AFreeType: TQJobDataFreeType): TWaitResult;
begin
Result := TQForJobs.For(AStartIndex, AStopIndex, AWorkerProc, AMsgWait, AData,
  AFreeType);
end;

class function TQWorkers.&For(const AStartIndex, AStopIndex: TForLoopIndexType;
  AWorkerProc: TQForJobProcG; AMsgWait: Boolean; AData: Pointer;
  AFreeType: TQJobDataFreeType): TWaitResult;
begin
Result := TQForJobs.For(AStartIndex, AStopIndex, AWorkerProc, AMsgWait, AData,
  AFreeType);
end;
{$IFDEF UNICODE}

class function TQWorkers.&For(const AStartIndex, AStopIndex: TForLoopIndexType;
  AWorkerProc: TQForJobProcA; AMsgWait: Boolean; AData: Pointer;
  AFreeType: TQJobDataFreeType): TWaitResult;
begin
Result := TQForJobs.For(AStartIndex, AStopIndex, AWorkerProc, AMsgWait, AData,
  AFreeType);
end;

function TQWorkers.At(AProc: TQJobProcA; const ATime: TDateTime;
  const AInterval: Int64; AData: Pointer; ARunInMainThread: Boolean;
  AFreeType: TQJobDataFreeType): IntPtr;
var
  AJob: PQJob;
  ADelay: Int64;
  ANow, ATemp: TDateTime;
begin
AJob := JobPool.Pop;
JobInitialize(AJob, AData, AFreeType, AInterval <= 0, ARunInMainThread);
TQJobProcA(AJob.WorkerProc.ProcA) := AProc;
AJob.IsAnonWorkerProc := True;
AJob.Interval := AInterval;
// ATime我们只要时间部分，日期忽略
ANow := Now;
ANow := ANow - Trunc(ANow);
ATemp := ATime - Trunc(ATime);
if ANow > ATemp then // 好吧，今天的点已经过了，算明天
  ADelay := Trunc(((1 + ANow) - ATemp) * Q1Day) // 延迟的时间，单位为0.1ms
else
  ADelay := Trunc((ATemp - ANow) * Q1Day);
AJob.FirstDelay := ADelay;
Result := Post(AJob);
end;
{$ENDIF}

function TQWorkers.Clear(AProc: TQJobProc; AData: Pointer;
  AMaxTimes: Integer): Integer;
var
  ACleared: Integer;
  AWaitParam: TWorkerWaitParam;
  function ClearSignalJobs: Integer;
  var
    I: Integer;
    AJob, ANext, APrior: PQJob;
    AList: PQHashList;
    ASignal: PQSignal;
  begin
  Result := 0;
  FLocker.Enter;
  try
    for I := 0 to FSignalJobs.BucketCount - 1 do
      begin
      AList := FSignalJobs.Buckets[I];
      if AList <> nil then
        begin
        ASignal := AList.Data;
        if ASignal.First <> nil then
          begin
          AJob := ASignal.First;
          APrior := nil;
          while (AJob <> nil) and (AMaxTimes <> 0) do
            begin
            ANext := AJob.Next;
            if SameWorkerProc(AJob.WorkerProc, AProc) and
              ((AData = Pointer(-1)) or (AJob.Data = AData)) then
              begin
              if ASignal.First = AJob then
                ASignal.First := ANext;
              if Assigned(APrior) then
                APrior.Next := ANext;
              AJob.Next := nil;
              FreeJob(AJob);
              Inc(Result);
              Dec(AMaxTimes);
              end
            else
              APrior := AJob;
            AJob := ANext;
            end;
          if AMaxTimes = 0 then
            Break;
          end;
        end;
      end;
  finally
    FLocker.Leave;
  end;
  end;

begin
Result := 0;
if Self <> nil then
  begin
  ACleared := FSimpleJobs.Clear(AProc, AData, AMaxTimes);
  Dec(AMaxTimes, ACleared);
  Inc(Result, ACleared);
  if AMaxTimes <> 0 then
    begin
    ACleared := FRepeatJobs.Clear(AProc, AData, AMaxTimes);
    Dec(AMaxTimes, ACleared);
    Inc(Result, ACleared);
    if AMaxTimes <> 0 then
      begin
      ACleared := ClearSignalJobs;
      Inc(Result, ACleared);
      if AMaxTimes <> 0 then
        begin
        AWaitParam.WaitType := 1;
        AWaitParam.Data := AData;
        AWaitParam.WorkerProc := TMethod(AProc);
        WaitRunningDone(AWaitParam);
        end;
      end;
    end;
  end;
end;

procedure TQWorkers.ClearWorkers;
var
  I: Integer;
  AInMainThread: Boolean;
{$IFDEF MSWINDOWS}
  function ThreadExists(AId: TThreadId): Boolean;
  var
    ASnapshot: THandle;
    AEntry: TThreadEntry32;
  begin
  Result := False;
  ASnapshot := CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
  if ASnapshot = INVALID_HANDLE_VALUE then
    Exit;
  try
    AEntry.dwSize := SizeOf(TThreadEntry32);
    if Thread32First(ASnapshot, AEntry) then
      begin
      repeat
        if AEntry.th32ThreadID = AId then
          begin
          Result := True;
          Break;
          end;
      until not Thread32Next(ASnapshot, AEntry);
      end;
  finally
    CloseHandle(ASnapshot);
  end;
  end;
  function WorkerExists: Boolean;
  var
    J: Integer;
  begin
  Result := False;
  FLocker.Enter;
  try
    J := FWorkerCount - 1;
    while J >= 0 do
      begin
      if ThreadExists(FWorkers[J].ThreadId) then
        begin
        Result := True;
        Break;
        end;
      Dec(J);
      end;
  finally
    FLocker.Leave;
  end;
  end;
{$ENDIF}

begin
FTerminating := True;
FLocker.Enter;
try
  FRepeatJobs.FFirstFireTime := 0;
  for I := 0 to FWorkerCount - 1 do
    FWorkers[I].FEvent.SetEvent;
finally
  FLocker.Leave;
end;
AInMainThread := GetCurrentThreadId = MainThreadId;
while (FWorkerCount > 0) {$IFDEF MSWINDOWS} and WorkerExists {$ENDIF} do
  begin
  if AInMainThread then
    ProcessAppMessage;
  Sleep(10);
  end;
for I := 0 to FWorkerCount - 1 do
  begin
  if FWorkers[I] <> nil then
    FreeObject(FWorkers[I]);
  end;
FWorkerCount := 0;
end;

constructor TQWorkers.Create(AMinWorkers: Integer);
var
  ACpuCount: Integer;
  I: Integer;
begin
FSimpleJobs := TQSimpleJobs.Create(Self);
FRepeatJobs := TQRepeatJobs.Create(Self);
FSignalJobs := TQHashTable.Create();
FSignalJobs.OnDelete := DoJobFree;
FSignalJobs.AutoSize := True;
FFireTimeout := DEFAULT_FIRE_TIMEOUT;
FStaticThread := TStaticThread.Create;
ACpuCount := GetCPUCount;
if AMinWorkers < 1 then
  FMinWorkers := 2
else
  FMinWorkers := AMinWorkers; // 最少工作者为2个
FMaxWorkers := (ACpuCount shl 1) + 1;
if FMaxWorkers <= FMinWorkers then
  FMaxWorkers := (FMinWorkers shl 1) + 1;
FLocker := TCriticalSection.Create;
FTerminating := False;
// 创建默认工作者
FWorkerCount := 0;
SetLength(FWorkers, FMaxWorkers + 1);
for I := 0 to FMinWorkers - 1 do
  FWorkers[I] := CreateWorker(True);
for I := 0 to FMinWorkers - 1 do
  begin
  FWorkers[I].FEvent.SetEvent;
  FWorkers[I].Suspended := False;
  end;
FMaxLongtimeWorkers := (FMaxWorkers shr 1);
{$IFDEF MSWINDOWS}
FMainWorker := AllocateHWnd(DoMainThreadWork);
{$ENDIF}
FStaticThread.Suspended := False;
end;

function TQWorkers.CreateWorker(ASuspended: Boolean): TQWorker;
begin
if FWorkerCount < FMaxWorkers then
  begin
  Result := TQWorker.Create(Self);
  FWorkers[FWorkerCount] := Result;
{$IFDEF MSWINDOWS}
  SetThreadCPU(Result.Handle, FWorkerCount mod GetCPUCount);
{$ELSE}
  SetThreadCPU(Result.ThreadId, FWorkerCount mod GetCPUCount);
{$ENDIF}
  Inc(FWorkerCount);
  if not ASuspended then
    begin
    Result.FPending := True;
    Result.FEvent.SetEvent;
    Result.Suspended := False;
    end;
  end
else
  Result := nil;
end;

function TQWorkers.Delay(AProc: TQJobProc; ADelay: Int64; AData: Pointer;
  ARunInMainThread: Boolean; AFreeType: TQJobDataFreeType): IntPtr;
var
  AJob: PQJob;
begin
AJob := JobPool.Pop;
JobInitialize(AJob, AData, AFreeType, True, ARunInMainThread);
{$IFDEF NEXTGEN}
PQJobProc(@AJob.WorkerProc)^ := AProc;
{$ELSE}
AJob.WorkerProc.Proc := AProc;
{$ENDIF}
if ADelay > 0 then
  AJob.FirstDelay := ADelay;
Result := Post(AJob);
end;
{$IFDEF UNICODE}

function TQWorkers.Delay(AProc: TQJobProcA; ADelay: Int64; AData: Pointer;
  ARunInMainThread: Boolean; AFreeType: TQJobDataFreeType): IntPtr;
var
  AJob: PQJob;
begin
AJob := JobPool.Pop;
JobInitialize(AJob, AData, AFreeType, True, ARunInMainThread);
TQJobProcA(AJob.WorkerProc.ProcA) := AProc;
AJob.IsAnonWorkerProc := True;
if ADelay > 0 then
  AJob.FirstDelay := ADelay;
Result := Post(AJob);
end;
{$ENDIF}

function TQWorkers.Delay(AProc: TQJobProcG; ADelay: Int64; AData: Pointer;
  ARunInMainThread: Boolean; AFreeType: TQJobDataFreeType): IntPtr;
begin
Result := Delay(MakeJobProc(AProc), ADelay, AData, ARunInMainThread, AFreeType);
end;

destructor TQWorkers.Destroy;
var
  T: Int64;
begin
ClearWorkers;
FLocker.Enter;
try
  FreeObject(FSimpleJobs);
  FreeObject(FRepeatJobs);
  FreeObject(FSignalJobs);
finally
  FreeObject(FLocker);
end;
{$IFDEF MSWINDOWS}
DeallocateHWnd(FMainWorker);
{$ENDIF}
FStaticThread.FreeOnTerminate := True;
FStaticThread.Terminate;
ThreadYield;
T := GetTimestamp;
while Assigned(FStaticThread) and (GetTimestamp - T < 12000) do
  Sleep(200);
if Assigned(FStaticThread) then
  FreeObject(FStaticThread);
inherited;
end;

procedure TQWorkers.DisableWorkers;
begin
AtomicIncrement(FDisableCount);
end;

procedure TQWorkers.DoCustomFreeData(AFreeType: TQJobDataFreeType;
  const AData: Pointer);
begin
if Assigned(FOnCustomFreeData) then
  FOnCustomFreeData(Self, AFreeType, AData);
end;

procedure TQWorkers.DoJobFree(ATable: TQHashTable; AHash: Cardinal;
  AData: Pointer);
var
  ASignal: PQSignal;
begin
ASignal := AData;
if ASignal.First <> nil then
  FreeJob(ASignal.First);
Dispose(ASignal);
end;
{$IFDEF MSWINDOWS}

procedure TQWorkers.DoMainThreadWork(var AMsg: TMessage);
var
  AJob: PQJob;
begin
if AMsg.MSG = WM_APP then
  begin
  AJob := PQJob(AMsg.WPARAM);
  try
    AJob.Worker.DoJob(AJob);
  except
    on E: Exception do
      begin
      if Assigned(FOnError) then
        FOnError(AJob, E, jesExecute);
      end;
  end;
  if AMsg.LPARAM <> 0 then
    TEvent(AMsg.LPARAM).SetEvent;
  end
else
  AMsg.Result := DefWindowProc(FMainWorker, AMsg.MSG, AMsg.WPARAM, AMsg.LPARAM);
end;

{$ENDIF}

procedure TQWorkers.EnableWorkers;
var
  ANeedCount: Integer;
begin
if AtomicDecrement(FDisableCount) = 0 then
  begin
  if (FSimpleJobs.Count > 0) or (FRepeatJobs.Count > 0) then
    begin
    ANeedCount := FSimpleJobs.Count + FRepeatJobs.Count;
    while ANeedCount > 0 do
      begin
      if not LookupIdleWorker(True) then
        Break;
      Dec(ANeedCount);
      end;
    end;
  end;
end;

function TQWorkers.EnumJobStates: TQJobStateArray;
var
  AJob: PQJob;
  I: Integer;
  ARunnings: TQJobStateArray;
  procedure EnumSimpleJobs;
  var
    AFirst: PQJob;
  begin
  I := 0;
  AFirst := FSimpleJobs.PopAll;
  AJob := AFirst;
  SetLength(Result, 4096);
  while AJob <> nil do
    begin
    if I >= Length(Result) then
      SetLength(Result, Length(Result) + 4096);
    Result[I].Handle := IntPtr(AJob);
    if AJob.IsAnonWorkerProc then
      IUnknown(AJob.WorkerProc.ProcA)._AddRef;
    Result[I].Proc := AJob.WorkerProc;
    Result[I].Flags := AJob.Flags;
    Result[I].PushTime := AJob.PushTime;
    AJob := AJob.Next;
    Inc(I);
    end;
  FSimpleJobs.Repush(AFirst);
  SetLength(Result, I);
  end;
  procedure EnumRepeatJobs;
  var
    ANode: TQRBNode;
    ATemp: TQJobStateArray;
    L: Integer;
  begin
  I := 0;
  FRepeatJobs.FLocker.Enter;
  try
    ANode := FRepeatJobs.FItems.First;
    SetLength(ATemp, FRepeatJobs.Count);
    while ANode <> nil do
      begin
      AJob := ANode.Data;
      while Assigned(AJob) do
        begin
        ATemp[I].Handle := IntPtr(AJob) or $01;
        if AJob.IsAnonWorkerProc then
          IUnknown(AJob.WorkerProc.ProcA)._AddRef;
        ATemp[I].Proc := AJob.WorkerProc;
        ATemp[I].Flags := AJob.Flags;
        ATemp[I].Runs := AJob.Runs;
        ATemp[I].PushTime := AJob.PushTime;
        ATemp[I].PopTime := AJob.PopTime;
        ATemp[I].AvgTime := AJob.AvgTime;
        ATemp[I].TotalTime := AJob.TotalUsedTime;
        ATemp[I].MaxTime := AJob.MaxUsedTime;
        ATemp[I].MinTime := AJob.MinUsedTime;
        ATemp[I].NextTime := AJob.NextTime;
        AJob := AJob.Next;
        Inc(I);
        end;
      ANode := ANode.Next;
      end;
  finally
    FRepeatJobs.FLocker.Leave;
  end;
  if I > 0 then
    begin
    L := Length(Result);
    SetLength(Result, Length(Result) + I);
    Move(ATemp[0], Result[L], I * SizeOf(TQJobState));
    end;
  end;
  procedure EnumSignalJobs;
  var
    ATemp: TQJobStateArray;
    AList: PQHashList;
    ASignal: PQSignal;
    L: Integer;
  begin
  L := 0;
  I := 0;
  FLocker.Enter;
  try
    SetLength(ATemp, 4096);
    while I < FSignalJobs.BucketCount do
      begin
      AList := FSignalJobs.Buckets[I];
      if AList <> nil then
        begin
        ASignal := AList.Data;
        if ASignal.First <> nil then
          begin
          AJob := ASignal.First;
          while AJob <> nil do
            begin
            if L >= Length(ATemp) then
              SetLength(ATemp, Length(ATemp) + 4096);
            ATemp[L].Handle := IntPtr(AJob) + $02;
            if AJob.IsAnonWorkerProc then
              IUnknown(AJob.WorkerProc.ProcA)._AddRef;
            ATemp[L].Runs := AJob.Runs;
            ATemp[L].Proc := AJob.WorkerProc;
            ATemp[L].Flags := AJob.Flags;
            ATemp[L].PushTime := AJob.PushTime;
            ATemp[L].PopTime := AJob.PopTime;
            ATemp[L].AvgTime := AJob.AvgTime;
            ATemp[L].TotalTime := AJob.TotalUsedTime;
            ATemp[L].MaxTime := AJob.MaxUsedTime;
            ATemp[L].MinTime := AJob.MinUsedTime;
            AJob := AJob.Next;
            Inc(L);
            end;
          end;
        end;
      Inc(I);
      end;
  finally
    FLocker.Leave;
  end;
  if L > 0 then
    begin
    I := Length(Result);
    SetLength(Result, Length(Result) + L);
    Move(ATemp[0], Result[I], L * SizeOf(TQJobState));
    end;
  end;
  procedure CheckRunnings;
  var
    C: Integer;
    J: Integer;
    AFound: Boolean;
  begin
  DisableWorkers;
  C := 0;
  FLocker.Enter;
  try
    SetLength(ARunnings, FWorkerCount);
    I := 0;
    while I < FWorkerCount do
      begin
      if FWorkers[I].IsExecuting then
        begin
        if (FWorkers[I].FActiveJobFlags and JOB_RUN_ONCE) <> 0 then
          ARunnings[C].Handle := IntPtr(FWorkers[I].FActiveJob)
        else if (FWorkers[I].FActiveJobFlags and JOB_SIGNAL_WAKEUP) <> 0 then
          ARunnings[C].Handle := IntPtr(FWorkers[I].FActiveJob) and $02
        else
          ARunnings[C].Handle := IntPtr(FWorkers[I].FActiveJob) and $01;
        ARunnings[C].Proc := FWorkers[I].FActiveJobProc;
        ARunnings[C].Flags := FWorkers[I].FActiveJobFlags;
        ARunnings[C].IsRunning := True;
        ARunnings[C].EscapedTime := GetTimestamp - FWorkers[I].FLastActiveTime;
        ARunnings[C].PopTime := FWorkers[I].FLastActiveTime;
        Inc(C);
        end;
      Inc(I);
      end;
  finally
    FLocker.Leave;
    EnableWorkers;
  end;
  SetLength(ARunnings, C);
  I := 0;
  while I < C do
    begin
    AFound := False;
    for J := 0 to High(Result) do
      begin
      if ARunnings[I].Handle = Result[J].Handle then
        begin
        AFound := True;
        Break;
        end;
      end;
    if not AFound then
      begin
      SetLength(Result, Length(Result) + 1);
      Result[Length(Result) - 1] := ARunnings[I];
      end;
    Inc(I);
    end;
  end;

  function IsRunning(AHandle: IntPtr): Boolean;
  var
    J: Integer;
  begin
  AHandle := AHandle and (not $03);
  Result := False;
  for J := 0 to High(ARunnings) do
    begin
    if AHandle = ARunnings[J].Handle then
      begin
      Result := True;
      Break;
      end;
    end;
  end;

begin
EnumSimpleJobs;
EnumRepeatJobs;
EnumSignalJobs;
CheckRunnings;
for I := 0 to High(Result) do
  Result[I].IsRunning := IsRunning(Result[I].Handle);
end;

function TQWorkers.EnumWorkerStatus: TQWorkerStatus;
var
  I: Integer;
  function GetMethodName(AMethod: TMethod): QStringW;
  var
    AObjName, AMethodName: QStringW;
{$IFDEF USE_MAP_SYMBOLS}
    ALoc: TQSymbolLocation;
{$ENDIF}
  begin
  if AMethod.Data <> nil then
    begin
    try
      AObjName := TObject(TObject(AMethod.Data)).ClassName;
{$IFDEF USE_MAP_SYMBOLS}
      if LocateSymbol(AMethod.Code, ALoc) then
        begin
        Result := ALoc.FunctionName;
        Exit;
        end
      else
        AMethodName := TObject(AMethod.Data).MethodName(AMethod.Code);
{$ELSE}
      AMethodName := TObject(AMethod.Data).MethodName(AMethod.Code);
{$ENDIF}
    except
      AObjName := IntToHex(NativeInt(AMethod.Data), SizeOf(Pointer) shl 1);
    end;
    if Length(AObjName) = 0 then
      AObjName := IntToHex(NativeInt(AMethod.Data), SizeOf(Pointer) shl 1);
    if Length(AMethodName) = 0 then
      AMethodName := IntToHex(NativeInt(AMethod.Code), SizeOf(Pointer) shl 1);
    Result := AObjName + '::' + AMethodName;
    end
  else if AMethod.Data <> nil then
    Result := IntToHex(NativeInt(AMethod.Code), SizeOf(Pointer) shl 1)
  else
    SetLength(Result, 0);
  end;

begin
DisableWorkers;
FLocker.Enter;
try
  SetLength(Result, Workers);
  for I := 0 to Workers - 1 do
    begin
    Result[I].Processed := FWorkers[I].FProcessed;
    Result[I].ThreadId := FWorkers[I].ThreadId;
    Result[I].IsIdle := FWorkers[I].IsIdle;
    Result[I].LastActive := FWorkers[I].FLastActiveTime;
    Result[I].Timeout := FWorkers[I].FTimeout;
    if not Result[I].IsIdle then
      begin
      Result[I].ActiveJob := GetMethodName(TMethod(FWorkers[I].FActiveJobProc));
      if Assigned(GetThreadStackInfo) then
        Result[I].Stacks := GetThreadStackInfo(FWorkers[I]);
      end;
    end;
finally
  FLocker.Leave;
  EnableWorkers;
end;
end;

procedure TQWorkers.FireSignalJob(ASignal: PQSignal; AData: Pointer;
  AFreeType: TQJobDataFreeType);
var
  AJob, ACopy: PQJob;
  ACount: PInteger;
begin
Inc(ASignal.Fired);
if AData <> nil then
  begin
  New(ACount);
  ACount^ := 1; // 初始值
  end
else
  ACount := nil;
AJob := ASignal.First;
while AJob <> nil do
  begin
  ACopy := JobPool.Pop;
  ACopy.Assign(AJob);
  JobInitialize(ACopy, AData, AFreeType, True, AJob.InMainThread);
  if ACount <> nil then
    begin
    AtomicIncrement(ACount^);
    ACopy.RefCount := ACount;
    end;
  ACopy.Source := AJob;
  FSimpleJobs.Push(ACopy);
  AJob := AJob.Next;
  end;
if AData <> nil then
  begin
  if AtomicDecrement(ACount^) = 0 then
    begin
    Dispose(ACount);
    FreeJobData(AData, AFreeType);
    end;
  end;
end;

procedure TQWorkers.FreeJob(AJob: PQJob);
var
  ANext: PQJob;
  AFreeData: Boolean;
begin
while AJob <> nil do
  begin
  ANext := AJob.Next;
  if AJob.Data <> nil then
    begin
    if AJob.IsSignalWakeup then
      begin
      AFreeData := AtomicDecrement(AJob.RefCount^) = 0;
      if AFreeData then
        Dispose(AJob.RefCount);
      end
    else
      AFreeData := AJob.IsDataOwner;
    if AFreeData then
      FreeJobData(AJob.Data, AJob.FreeType);
    end;
  JobPool.Push(AJob);
  AJob := ANext;
  end;
end;

procedure TQWorkers.FreeJobData(AData: Pointer; AFreeType: TQJobDataFreeType);
begin
if AData <> nil then
  begin
  try
    case AFreeType of
      jdfFreeAsObject:
        FreeObject(TObject(AData));
      jdfFreeAsSimpleRecord:
        Dispose(AData);
      jdfFreeAsInterface:
        IUnknown(AData)._Release
    else
      DoCustomFreeData(AFreeType, AData);
    end;
  except
    on E: Exception do
      if Assigned(FOnError) then
        FOnError(nil, E, jesFreeData);
  end;
  end;
end;

function TQWorkers.GetBusyCount: Integer;
begin
Result := FBusyCount;
end;

function TQWorkers.GetEnabled: Boolean;
begin
Result := (FDisableCount = 0);
end;

function TQWorkers.GetIdleWorkers: Integer;
begin
Result := FWorkerCount - BusyWorkers;
end;

function TQWorkers.GetNextRepeatJobTime: Int64;
begin
Result := FRepeatJobs.FFirstFireTime;
end;

function TQWorkers.GetOutWorkers: Boolean;
begin
Result := (FBusyCount = MaxWorkers);
end;

function TQWorkers.LongtimeJob(AProc: TQJobProc; AData: Pointer;
  AFreeType: TQJobDataFreeType): IntPtr;
var
  AJob: PQJob;
begin
if AtomicIncrement(FLongTimeWorkers) <= FMaxLongtimeWorkers then
  begin
  AJob := JobPool.Pop;
  JobInitialize(AJob, AData, AFreeType, True, False);
  AJob.SetFlags(JOB_LONGTIME, True);
{$IFDEF NEXTGEN}
  PQJobProc(@AJob.WorkerProc)^ := AProc;
{$ELSE}
  AJob.WorkerProc.Proc := AProc;
{$ENDIF}
  Result := Post(AJob);
  end
else
  begin
  AtomicDecrement(FLongTimeWorkers);
  Result := 0;
  end;
end;
{$IFDEF UNICODE}

function TQWorkers.LongtimeJob(AProc: TQJobProcA; AData: Pointer;
  AFreeType: TQJobDataFreeType = jdfFreeByUser): IntPtr;
var
  AJob: PQJob;
begin
if AtomicIncrement(FLongTimeWorkers) <= FMaxLongtimeWorkers then
  begin
  AJob := JobPool.Pop;
  JobInitialize(AJob, AData, AFreeType, True, False);
  AJob.SetFlags(JOB_LONGTIME, True);
  TQJobProcA(AJob.WorkerProc.ProcA) := AProc;
  AJob.IsAnonWorkerProc := True;
  Result := Post(AJob);
  end
else
  begin
  AtomicDecrement(FLongTimeWorkers);
  Result := 0;
  end;
end;
{$ENDIF}

function TQWorkers.LongtimeJob(AProc: TQJobProcG; AData: Pointer;
  AFreeType: TQJobDataFreeType): IntPtr;
begin
Result := LongtimeJob(MakeJobProc(AProc), AData, AFreeType);
end;

function TQWorkers.LookupIdleWorker(AFromSimple: Boolean): Boolean;
var
  AWorker: TQWorker;
  I: Integer;
  AMoreWorkerNeeded: Boolean;
begin
if FBusyCount >= FMaxWorkers then
  begin
  Result := False;
  Exit;
  end
else if (FDisableCount <> 0) or FTerminating then
  begin
  Result := False;
  Exit;
  end;
// 如果有正在解雇的工作者，那么等待完成
while FFiringWorkerCount > 0 do
  ThreadYield;
AWorker := nil;
AMoreWorkerNeeded := False;
FLocker.Enter;
try
  I := 0;
  while I < FWorkerCount do
    begin
    if (FWorkers[I].IsIdle) and (FWorkers[I].IsRunning) and
      (not(FWorkers[I].IsFiring or FWorkers[I].FPending)) then
      begin
      FWorkers[I].FPending := True;
      FWorkers[I].FEvent.SetEvent;
      if AWorker=nil then
        begin
        AWorker := FWorkers[I];
        AMoreWorkerNeeded := (not AFromSimple) or
          (FRepeatJobs.FFirstFireTime = 0);
        end
      else
        AMoreWorkerNeeded:=False;
      if not AMoreWorkerNeeded then
        Break;
      end;
    Inc(I);
    end;
  if (AWorker = nil) or AMoreWorkerNeeded then
    AWorker := CreateWorker(False);
finally
  FLocker.Leave;
end;
Result := AWorker <> nil;
//if Result then
//  ThreadYield;
end;

procedure TQWorkers.NewWorkerNeeded;
begin
TStaticThread(FStaticThread).CheckNeeded;
end;

function TQWorkers.PeekJobState(AHandle: IntPtr;
  var AResult: TQJobState): Boolean;
var
  AJob: PQJob;
  ARunnings: array of IntPtr;
  procedure PeekSimpleJob;
  var
    AFirst: PQJob;
  begin
  AFirst := FSimpleJobs.PopAll;
  AJob := AFirst;
  while AJob <> nil do
    begin
    if IntPtr(AJob) = AHandle then
      begin
      AResult.Handle := IntPtr(AJob);
      if AJob.IsAnonWorkerProc then
        IUnknown(AJob.WorkerProc.ProcA)._AddRef;
      AResult.Proc := AJob.WorkerProc;
      AResult.Flags := AJob.Flags;
      AResult.PushTime := AJob.PushTime;
      Result := True;
      Break;
      end;
    AJob := AJob.Next;
    end;
  FSimpleJobs.Repush(AFirst);
  end;
  procedure PeekRepeatJob;
  var
    ANode: TQRBNode;
  begin
  AHandle := AHandle and (not $03);
  FRepeatJobs.FLocker.Enter;
  try
    ANode := FRepeatJobs.FItems.First;
    while ANode <> nil do
      begin
      AJob := ANode.Data;
      while Assigned(AJob) do
        begin
        if IntPtr(AJob) = AHandle then
          begin
          AResult.Handle := IntPtr(AJob) or $01;
          if AJob.IsAnonWorkerProc then
            IUnknown(AJob.WorkerProc.ProcA)._AddRef;
          AResult.Proc := AJob.WorkerProc;
          AResult.Flags := AJob.Flags;
          AResult.Runs := AJob.Runs;
          AResult.PushTime := AJob.PushTime;
          AResult.PopTime := AJob.PopTime;
          AResult.AvgTime := AJob.AvgTime;
          AResult.TotalTime := AJob.TotalUsedTime;
          AResult.MaxTime := AJob.MaxUsedTime;
          AResult.MinTime := AJob.MinUsedTime;
          AResult.NextTime := AJob.NextTime;
          Result := True;
          Exit;
          end;
        AJob := AJob.Next;
        end;
      ANode := ANode.Next;
      end;
  finally
    FRepeatJobs.FLocker.Leave;
  end;
  end;
  procedure PeekSignalJob;
  var
    ATemp: TQJobStateArray;
    AList: PQHashList;
    ASignal: PQSignal;
    I: Integer;
  begin
  I := 0;
  AHandle := AHandle and (not $03);
  FLocker.Enter;
  try
    SetLength(ATemp, 4096);
    while I < FSignalJobs.BucketCount do
      begin
      AList := FSignalJobs.Buckets[I];
      if AList <> nil then
        begin
        ASignal := AList.Data;
        if ASignal.First <> nil then
          begin
          AJob := ASignal.First;
          while AJob <> nil do
            begin
            if IntPtr(AJob) = AHandle then
              begin
              AResult.Handle := IntPtr(AJob) + $02;
              if AJob.IsAnonWorkerProc then
                IUnknown(AJob.WorkerProc.ProcA)._AddRef;
              AResult.Runs := AJob.Runs;
              AResult.Proc := AJob.WorkerProc;
              AResult.Flags := AJob.Flags;
              AResult.PushTime := AJob.PushTime;
              AResult.PopTime := AJob.PopTime;
              AResult.AvgTime := AJob.AvgTime;
              AResult.TotalTime := AJob.TotalUsedTime;
              AResult.MaxTime := AJob.MaxUsedTime;
              AResult.MinTime := AJob.MinUsedTime;
              Result := True;
              Exit;
              end;
            AJob := AJob.Next;
            end;
          end;
        end;
      Inc(I);
      end;
  finally
    FLocker.Leave;
  end;
  end;
  procedure CheckRunnings;
  var
    I: Integer;
  begin
  DisableWorkers;
  FLocker.Enter;
  try
    SetLength(ARunnings, FWorkerCount);
    I := 0;
    while I < FWorkerCount do
      begin
      if FWorkers[I].IsExecuting then
        begin
        if IntPtr(FWorkers[I].FActiveJob) = AHandle then
          begin
          AResult.IsRunning := True;
          Exit;
          end;
        end;
      Inc(I);
      end;
  finally
    FLocker.Leave;
    EnableWorkers;
  end;
  end;

begin
Result := False;
case AHandle and $03 of
  0:
    PeekSimpleJob;
  1:
    PeekRepeatJob;
  2:
    PeekSignalJob;
end;
CheckRunnings;
end;

function TQWorkers.Popup: PQJob;
begin
Result := FSimpleJobs.Pop;
if Result = nil then
  Result := FRepeatJobs.Pop;
end;

function TQWorkers.RegisterSignal(const AName: QStringW): Integer;
var
  ASignal: PQSignal;
begin
FLocker.Enter;
try
  Result := SignalIdByName(AName);
  if Result < 0 then
    begin
    Inc(FMaxSignalId);
    New(ASignal);
    ASignal.Id := FMaxSignalId;
    ASignal.Fired := 0;
    ASignal.Name := AName;
    ASignal.First := nil;
    FSignalJobs.Add(ASignal, ASignal.Id);
    Result := ASignal.Id;
    // OutputDebugString(PWideChar('Signal '+IntToStr(ASignal.Id)+' Allocate '+IntToHex(NativeInt(ASignal),8)));
    end;
finally
  FLocker.Leave;
end;
end;

procedure TQWorkers.SetEnabled(const Value: Boolean);
begin
if Value then
  EnableWorkers
else
  DisableWorkers;
end;

procedure TQWorkers.SetFireTimeout(const Value: Cardinal);
begin
if Value = 0 then
  FFireTimeout := MaxInt
else
  FFireTimeout := Value;
end;

procedure TQWorkers.SetMaxLongtimeWorkers(const Value: Integer);
begin
if FMaxLongtimeWorkers <> Value then
  begin
  if Value > (MaxWorkers shr 1) then
    raise Exception.Create(STooManyLongtimeWorker);
  FMaxLongtimeWorkers := Value;
  end;
end;

procedure TQWorkers.SetMaxWorkers(const Value: Integer);
var
  ATemp, AMaxLong: Integer;
begin
if (Value >= 2) and (FMaxWorkers <> Value) then
  begin
  AtomicExchange(ATemp, FLongTimeWorkers);
  AtomicExchange(FLongTimeWorkers, 0); // 强制置0，防止有新入的长时间作业
  AMaxLong := Value shr 1;
  FLocker.Enter;
  try
    if FLongTimeWorkers < AMaxLong then // 已经进行的长时间作业数小于一半的工作者
      begin
      if ATemp < AMaxLong then
        AMaxLong := ATemp;
      if FMaxWorkers > Value then
        begin
        FMaxWorkers := Value;
        SetLength(FWorkers, Value + 1);
        end
      else
        begin
        FMaxWorkers := Value;
        SetLength(FWorkers, Value + 1);
        end;
      end;
  finally
    FLocker.Leave;
    AtomicExchange(FLongTimeWorkers, AMaxLong);
  end;
  end;
end;

procedure TQWorkers.SetMinWorkers(const Value: Integer);
begin
if FMinWorkers <> Value then
  begin
  if Value < 1 then
    raise Exception.Create(STooFewWorkers);
  FMinWorkers := Value;
  end;
end;

procedure TQWorkers.Signal(AId: Integer; AData: Pointer;
  AFreeType: TQJobDataFreeType);
var
  AFound: Boolean;
  ASignal: PQSignal;
begin
AFound := False;
FLocker.Enter;
try
  ASignal := FSignalJobs.FindFirstData(AId);
  if ASignal <> nil then
    begin
    AFound := True;
    FireSignalJob(ASignal, AData, AFreeType);
    end
  else
    FreeJobData(AData, AFreeType);
finally
  FLocker.Leave;
end;
if AFound then
  LookupIdleWorker(True);
end;

procedure TQWorkers.Signal(const AName: QStringW; AData: Pointer;
  AFreeType: TQJobDataFreeType);
var
  I: Integer;
  ASignal: PQSignal;
  AFound: Boolean;
begin
AFound := False;
FLocker.Enter;
try
  for I := 0 to FSignalJobs.BucketCount - 1 do
    begin
    if FSignalJobs.Buckets[I] <> nil then
      begin
      ASignal := FSignalJobs.Buckets[I].Data;
      if (Length(ASignal.Name) = Length(AName)) and (ASignal.Name = AName) then
        begin
        AFound := True;
        FireSignalJob(ASignal, AData, AFreeType);
        Break;
        end;
      end;
    end;
finally
  FLocker.Leave;
end;
if AFound then
  LookupIdleWorker(True)
else
  FreeJobData(AData, AFreeType);
end;

function TQWorkers.SignalIdByName(const AName: QStringW): Integer;
var
  I: Integer;
  ASignal: PQSignal;
begin
Result := -1;
for I := 0 to FSignalJobs.BucketCount - 1 do
  begin
  if FSignalJobs.Buckets[I] <> nil then
    begin
    ASignal := FSignalJobs.Buckets[I].Data;
    if (Length(ASignal.Name) = Length(AName)) and (ASignal.Name = AName) then
      begin
      Result := ASignal.Id;
      Exit;
      end;
    end;
  end;
end;

procedure TQWorkers.SignalWorkDone(AJob: PQJob; AUsedTime: Int64);
var
  ASignal: PQSignal;
  ATemp, APrior: PQJob;
begin
FLocker.Enter;
try
  ASignal := FSignalJobs.FindFirstData(AJob.SignalId);
  ATemp := ASignal.First;
  APrior := nil;
  while ATemp <> nil do
    begin
    if ATemp = AJob.Source then
      begin
      if AJob.IsTerminated then
        begin
        if APrior <> nil then
          APrior.Next := ATemp.Next
        else
          ASignal.First := ATemp.Next;
        ATemp.Next := nil;
        FreeJob(ATemp);
        end
      else
        begin
        // 更新信号作业的统计信息
        Inc(ATemp.Runs);
        if AUsedTime > 0 then
          begin
          if ATemp.MinUsedTime = 0 then
            ATemp.MinUsedTime := AUsedTime
          else if AUsedTime < ATemp.MinUsedTime then
            ATemp.MinUsedTime := AUsedTime;
          if ATemp.MaxUsedTime = 0 then
            ATemp.MaxUsedTime := AUsedTime
          else if AUsedTime > ATemp.MaxUsedTime then
            ATemp.MaxUsedTime := AUsedTime;
          Break;
          end;
        end;
      end;
    APrior := ATemp;
    ATemp := ATemp.Next;
    end;
finally
  FLocker.Leave;
end;
end;

procedure TQWorkers.ValidWorkers;
{$IFDEF VALID_WORKERS}
var
  I: Integer;
{$ENDIF}
begin
{$IFDEF VALID_WORKERS}
for I := 0 to FWorkerCount - 1 do
  begin
  if FWorkers[I] = nil then
    OutputDebugString('Workers array bad')
  else if FWorkers[I].FIndex <> I then
    OutputDebugString('Workers index bad');
  end;
{$ENDIF}
end;

procedure TQWorkers.WorkerTimeout(AWorker: TQWorker);
begin
if FWorkerCount - AtomicIncrement(FFiringWorkerCount) < FMinWorkers then
  AtomicDecrement(FFiringWorkerCount)
else
  begin
  AWorker.SetFlags(WORKER_FIRING, True);
  AWorker.Terminate;
  end;
end;

procedure TQWorkers.WorkerTerminate(AWorker: TQWorker);
var
  I, J: Integer;
begin
FLocker.Enter;
try
  Dec(FWorkerCount);
  if AWorker.IsFiring then
    AtomicDecrement(FFiringWorkerCount);
  // 如果是当前忙碌的工作者被解雇
  if FWorkerCount = 0 then
    FWorkers[0] := nil
  else
    begin
    for I := 0 to FWorkerCount do
      begin
      if AWorker = FWorkers[I] then
        begin
        for J := I to FWorkerCount do
          FWorkers[J] := FWorkers[J + 1];
        Break;
        end;
      end;
    end;
finally
  FLocker.Leave;
end;
end;

function TQWorkers.Wait(AProc: TQJobProc; ASignalId: Integer;
  ARunInMainThread: Boolean): IntPtr;
var
  AJob: PQJob;
  ASignal: PQSignal;
begin
if not FTerminating then
  begin
  AJob := JobPool.Pop;
  JobInitialize(AJob, nil, jdfFreeByUser, False, ARunInMainThread);
{$IFDEF NEXTGEN}
  PQJobProc(@AJob.WorkerProc)^ := AProc;
{$ELSE}
  AJob.WorkerProc.Proc := AProc;
{$ENDIF}
//  Assert(AJob.WorkerProc.Code<>nil);
  AJob.SignalId := ASignalId;
  AJob.SetFlags(JOB_SIGNAL_WAKEUP, True);
  AJob.PushTime := GetTimestamp;
  Result := 0;
  FLocker.Enter;
  try
    ASignal := FSignalJobs.FindFirstData(ASignalId);
    if ASignal <> nil then
      begin
      AJob.Next := ASignal.First;
      ASignal.First := AJob;
      Result := IntPtr(AJob) + $02;
      end;
  finally
    FLocker.Leave;
    if Result = 0 then
      JobPool.Push(AJob);
  end;
  end
else
  Result := 0;
end;
{$IFDEF UNICODE}

function TQWorkers.Wait(AProc: TQJobProcA; ASignalId: Integer;
  ARunInMainThread: Boolean): IntPtr;
var
  AJob: PQJob;
  ASignal: PQSignal;
begin
if not FTerminating then
  begin
  AJob := JobPool.Pop;
  JobInitialize(AJob, nil, jdfFreeByUser, False, ARunInMainThread);
  TQJobProcA(AJob.WorkerProc.ProcA) := AProc;
  AJob.IsAnonWorkerProc := True;
  AJob.SignalId := ASignalId;
  AJob.SetFlags(JOB_SIGNAL_WAKEUP, True);
  AJob.PushTime := GetTimestamp;
  Result := 0;
  FLocker.Enter;
  try
    ASignal := FSignalJobs.FindFirstData(ASignalId);
    if ASignal <> nil then
      begin
      AJob.Next := ASignal.First;
      ASignal.First := AJob;
      Result := IntPtr(AJob) + $02;
      end;
  finally
    FLocker.Leave;
    if Result = 0 then
      JobPool.Push(AJob);
  end;
  end
else
  Result := 0;
end;
{$ENDIF}

function TQWorkers.Wait(AProc: TQJobProcG; ASignalId: Integer;
  ARunInMainThread: Boolean): IntPtr;
begin
Result := Wait(MakeJobProc(AProc), ASignalId, ARunInMainThread);
end;

procedure TQWorkers.WaitRunningDone(const AParam: TWorkerWaitParam);
var
  AInMainThread: Boolean;
  function HasJobRunning: Boolean;
  var
    I: Integer;
    AJob: PQJob;
  begin
  Result := False;
  DisableWorkers;
  FLocker.Enter;
  try
    for I := 0 to FWorkerCount - 1 do
      begin
      if FWorkers[I].IsLookuping then // 还未就绪，所以在下次查询
        begin
        Result := True;
        Break;
        end
      else if FWorkers[I].IsExecuting then
        begin
        if not FWorkers[I].IsCleaning then
          begin
          AJob := FWorkers[I].FActiveJob;
          case AParam.WaitType of
            0: // ByObject
              Result := TMethod(FWorkers[I].FActiveJobProc).Data = AParam.Bound;
            1: // ByData
              Result := (TMethod(FWorkers[I].FActiveJobProc)
                .Code = TMethod(AParam.WorkerProc).Code) and
                (TMethod(FWorkers[I].FActiveJobProc)
                .Data = TMethod(AParam.WorkerProc).Data) and
                ((AParam.Data = INVALID_JOB_DATA) or
                (FWorkers[I].FActiveJobData = AParam.Data));
            2: // BySignalSource
              Result := (FWorkers[I].FActiveJobSource = AParam.SourceJob);
            3: // ByGroup
              Result := (FWorkers[I].FActiveJobGroup = AParam.Group);
            4: // ByJob
              Result := (AJob = AParam.SourceJob);
            $FF: // 所有
              Result := True;
          else
            begin
            if Assigned(FOnError) then
              FOnError(AJob, Exception.CreateFmt(SBadWaitDoneParam,
                [AParam.WaitType]), jesWaitDone)
            else
              raise Exception.CreateFmt(SBadWaitDoneParam, [AParam.WaitType]);
            end;
          end;
          if Result then
            FWorkers[I].FTerminatingJob := AJob;
          end;
        end;
      end;
  finally
    FLocker.Leave;
    EnableWorkers;
  end;
  end;

begin
AInMainThread := GetCurrentThreadId = MainThreadId;
repeat
  if HasJobRunning then
    begin
    if AInMainThread then
      // 如果是在主线程中清理，由于作业可能在主线程执行，可能已经投寄尚未执行，所以必需让其能够执行
      ProcessAppMessage;
    Sleep(10);
    end
  else // 没找到
    Break;
until 1 > 2;
end;

procedure TQWorkers.WaitSignalJobsDone(AJob: PQJob);
begin
TEvent(AJob.Data).SetEvent;
end;

function TQWorkers.Clear(ASignalName: QStringW): Integer;
var
  I: Integer;
  ASignal: PQSignal;
  AJob: PQJob;
begin
Result := 0;
FLocker.Enter;
try
  AJob := nil;
  for I := 0 to FSignalJobs.BucketCount - 1 do
    begin
    if FSignalJobs.Buckets[I] <> nil then
      begin
      ASignal := FSignalJobs.Buckets[I].Data;
      if ASignal.Name = ASignalName then
        begin
        AJob := ASignal.First;
        ASignal.First := nil;
        Break;
        end;
      end;
    end;
finally
  FLocker.Leave;
end;
if AJob <> nil then
  ClearSignalJobs(AJob);
end;
{$IFDEF UNICODE}

function TQWorkers.At(AProc: TQJobProcA; const ADelay, AInterval: Int64;
  AData: Pointer; ARunInMainThread: Boolean;
  AFreeType: TQJobDataFreeType): IntPtr;
var
  AJob: PQJob;
begin
AJob := JobPool.Pop;
JobInitialize(AJob, AData, AFreeType, AInterval <= 0, ARunInMainThread);
TQJobProcA(AJob.WorkerProc.ProcA) := AProc;
AJob.IsAnonWorkerProc := True;
AJob.Interval := AInterval;
AJob.FirstDelay := ADelay;
Result := Post(AJob);
end;
{$ENDIF}

function TQWorkers.At(AProc: TQJobProcG; const ADelay, AInterval: Int64;
  AData: Pointer; ARunInMainThread: Boolean;
  AFreeType: TQJobDataFreeType): IntPtr;
begin
Result := At(MakeJobProc(AProc), ADelay, AInterval, AData, ARunInMainThread,
  AFreeType);
end;

function TQWorkers.At(AProc: TQJobProcG; const ATime: TDateTime;
  const AInterval: Int64; AData: Pointer; ARunInMainThread: Boolean;
  AFreeType: TQJobDataFreeType): IntPtr;
begin
Result := At(MakeJobProc(AProc), ATime, AInterval, AData, ARunInMainThread,
  AFreeType);
end;

function TQWorkers.Clear(ASignalId: Integer): Integer;
var
  I: Integer;
  ASignal: PQSignal;
  AJob: PQJob;
begin
FLocker.Enter;
try
  AJob := nil;
  for I := 0 to FSignalJobs.BucketCount - 1 do
    begin
    if FSignalJobs.Buckets[I] <> nil then
      begin
      ASignal := FSignalJobs.Buckets[I].Data;
      if ASignal.Id = ASignalId then
        begin
        AJob := ASignal.First;
        ASignal.First := nil;
        Break;
        end;
      end;
    end;
finally
  FLocker.Leave;
end;
if AJob <> nil then
  Result := ClearSignalJobs(AJob)
else
  Result := 0;
end;

procedure TQWorkers.Clear;
var
  I: Integer;
  AParam: TWorkerWaitParam;
  ASignal: PQSignal;
begin
DisableWorkers; // 避免工作者取得新的作业
try
  FSimpleJobs.Clear;
  FRepeatJobs.Clear;
  FLocker.Enter;
  try
    for I := 0 to FSignalJobs.BucketCount - 1 do
      begin
      if Assigned(FSignalJobs.Buckets[I]) then
        begin
        ASignal := FSignalJobs.Buckets[I].Data;
        FreeJob(ASignal.First);
        ASignal.First := nil;
        end;
      end;
  finally
    FLocker.Leave;
  end;
  AParam.WaitType := $FF;
  WaitRunningDone(AParam);
finally
  EnableWorkers;
end;
end;

function TQWorkers.ClearSignalJobs(ASource: PQJob): Integer;
var
  AFirst, ALast, APrior, ANext: PQJob;
  ACount: Integer;
  AWaitParam: TWorkerWaitParam;
begin
Result := 0;
AFirst := nil;
APrior := nil;
FSimpleJobs.FLocker.Enter;
try
  ALast := FSimpleJobs.FFirst;
  ACount := FSimpleJobs.Count;
  FSimpleJobs.FFirst := nil;
  FSimpleJobs.FLast := nil;
  FSimpleJobs.FCount := 0;
finally
  FSimpleJobs.FLocker.Leave;
end;
while ALast <> nil do
  begin
  if (ALast.IsSignalWakeup) and (ALast.Source = ASource) then
    begin
    ANext := ALast.Next;
    ALast.Next := nil;
    FreeJob(ALast);
    ALast := ANext;
    if APrior <> nil then
      APrior.Next := ANext;
    Dec(ACount);
    Inc(Result);
    end
  else
    begin
    if AFirst = nil then
      AFirst := ALast;
    APrior := ALast;
    ALast := ALast.Next;
    end;
  end;
if ACount > 0 then
  begin
  FSimpleJobs.FLocker.Enter;
  try
    APrior.Next := FSimpleJobs.FFirst;
    FSimpleJobs.FFirst := AFirst;
    Inc(FSimpleJobs.FCount, ACount);
    if FSimpleJobs.FLast = nil then
      FSimpleJobs.FLast := APrior;
  finally
    FSimpleJobs.FLocker.Leave;
  end;
  end;
AWaitParam.WaitType := 2;
AWaitParam.SourceJob := ASource;
WaitRunningDone(AWaitParam);
FreeJob(ASource);
end;
{$IFDEF UNICODE}

function TQWorkers.Post(AProc: TQJobProcA; AInterval: Int64; AData: Pointer;
  ARunInMainThread: Boolean; AFreeType: TQJobDataFreeType): IntPtr;
var
  AJob: PQJob;
begin
AJob := JobPool.Pop;
JobInitialize(AJob, AData, AFreeType, AInterval <= 0, ARunInMainThread);
TQJobProcA(AJob.WorkerProc.ProcA) := AProc;
AJob.IsAnonWorkerProc := True;
AJob.Interval := AInterval;
Result := Post(AJob);
end;
{$ENDIF}

function TQWorkers.Post(AProc: TQJobProcG; AInterval: Int64; AData: Pointer;
  ARunInMainThread: Boolean; AFreeType: TQJobDataFreeType): IntPtr;
begin
Result := Post(MakeJobProc(AProc), AInterval, AData, ARunInMainThread,
  AFreeType);
end;

procedure TQWorkers.ClearSingleJob(AHandle: IntPtr);
var
  AInstance: PQJob;
  AWaitParam: TWorkerWaitParam;

  function RemoveSignalJob: PQJob;
  var
    I: Integer;
    AJob, ANext, APrior: PQJob;
    AList: PQHashList;
    ASignal: PQSignal;
  begin
  Result := nil;
  FLocker.Enter;
  try
    for I := 0 to FSignalJobs.BucketCount - 1 do
      begin
      AList := FSignalJobs.Buckets[I];
      if AList <> nil then
        begin
        ASignal := AList.Data;
        if ASignal.First <> nil then
          begin
          AJob := ASignal.First;
          APrior := nil;
          while AJob <> nil do
            begin
            ANext := AJob.Next;
            if AJob = AInstance then
              begin
              if ASignal.First = AJob then
                ASignal.First := ANext;
              if Assigned(APrior) then
                APrior.Next := ANext;
              AJob.Next := nil;
              Result := AJob;
              Exit;
              end
            else
              APrior := AJob;
            AJob := ANext;
            end;
          end;
        end;
      end;
  finally
    FLocker.Leave;
  end;
  end;
  function ClearSignalJob: Boolean;
  var
    AJob: PQJob;
  begin
  AJob := RemoveSignalJob;
  if Assigned(AJob) then
    ClearSignalJobs(AJob);
  Result := AJob <> nil;
  end;

begin
AInstance := Pointer(AHandle and (not $03));
FillChar(AWaitParam, SizeOf(TWorkerWaitParam), 0);
AWaitParam.SourceJob := AInstance;
case AHandle and $03 of
  0: // SimpleJobs
    begin
    if FSimpleJobs.Clear(AHandle) then // 简单作业要么在队列中，要么不在
      Exit;
    AWaitParam.WaitType := 4;
    end;
  1: // RepeatJobs
    begin
    if not FRepeatJobs.Clear(AHandle) then // 重复队列如果不在队列中，说明已经被清除了
      Exit;
    AWaitParam.WaitType := 2;
    end;
  2: // SignalJobs;
    begin
    if ClearSignalJob then
      Exit;
    AWaitParam.WaitType := 2;
    end;
end;
WaitRunningDone(AWaitParam);
end;

function TQWorkers.ClearJobs(AHandles: PIntPtr; ACount: Integer): Integer;
var
  ASimpleHandles: array of IntPtr;
  ARepeatHandles: array of IntPtr;
  ASignalHandles: array of IntPtr;
  ASimpleCount, ARepeatCount, ASignalCount: Integer;
  I: Integer;
  AWaitParam: TWorkerWaitParam;
  function SignalJobCanRemove(AHandle: IntPtr): Boolean;
  var
    T: Integer;
  begin
  Result := False;
  for T := 0 to ASignalCount - 1 do
    begin
    if ASignalHandles[T] = AHandle then
      begin
      Result := True;
      Exit;
      end;
    end;
  end;
  function ClearSignals: Integer;
  var
    I: Integer;
    AJob, ANext, APrior, AFirst: PQJob;
    AList: PQHashList;
    ASignal: PQSignal;
  begin
  Result := 0;
  AFirst := nil;
  FLocker.Enter;
  try
    for I := 0 to FSignalJobs.BucketCount - 1 do
      begin
      AList := FSignalJobs.Buckets[I];
      if AList <> nil then
        begin
        ASignal := AList.Data;
        if ASignal.First <> nil then
          begin
          AJob := ASignal.First;
          APrior := nil;
          while AJob <> nil do
            begin
            ANext := AJob.Next;
            if SignalJobCanRemove(IntPtr(AJob)) then
              begin
              if ASignal.First = AJob then
                ASignal.First := ANext;
              if Assigned(APrior) then
                APrior.Next := ANext;
              AJob.Next := nil;
              if Assigned(AFirst) then
                AJob.Next := AFirst;
              AFirst := AJob;
              end
            else
              APrior := AJob;
            AJob := ANext;
            Inc(Result);
            end;
          end;
        end;
      end;
  finally
    FLocker.Leave;
  end;
  while AFirst <> nil do
    begin
    ANext := AFirst.Next;
    AFirst.Next := nil;
    ClearSignalJobs(AFirst);
    AFirst := ANext;
    end;
  end;

begin
Result := 0;
SetLength(ASimpleHandles, ACount);
SetLength(ARepeatHandles, ACount);
SetLength(ASignalHandles, ACount);
ASimpleCount := 0;
ARepeatCount := 0;
ASignalCount := 0;
I := 0;
while I < ACount do
  begin
  case (IntPtr(AHandles^) and $03) of
    0: // Simple Jobs
      begin
      ASimpleHandles[ASimpleCount] := (IntPtr(AHandles^) and (not $03));
      Inc(ASimpleCount);
      end;
    1: // RepeatJobs
      begin
      ARepeatHandles[ARepeatCount] := (IntPtr(AHandles^) and (not $03));
      Inc(ARepeatCount);
      end;
    2: // SignalJobs
      begin
      ASignalHandles[ASignalCount] := (IntPtr(AHandles^) and (not $03));
      Inc(ASignalCount);
      end;
  end;
  Inc(I);
  end;
if ASimpleCount > 0 then
  Inc(Result, FSimpleJobs.Clear(@ASimpleHandles[0], ASimpleCount));
if ARepeatCount > 0 then
  Inc(Result, FRepeatJobs.Clear(@ARepeatHandles[0], ARepeatCount));
if ASignalCount > 0 then
  Inc(Result, ClearSignals);
FillChar(AWaitParam, SizeOf(TWorkerWaitParam), 0);
I := 0;
while I < ASimpleCount do
  begin
  if ASimpleHandles[I] <> 0 then
    begin
    AWaitParam.SourceJob := Pointer(ASimpleHandles[I]);
    AWaitParam.WaitType := 4;
    WaitRunningDone(AWaitParam);
    Inc(Result);
    end;
  Inc(I);
  end;
I := 0;
while I < ARepeatCount do
  begin
  if ARepeatHandles[I] <> 0 then
    begin
    AWaitParam.SourceJob := Pointer(ARepeatHandles[I]);
    AWaitParam.WaitType := 2;
    WaitRunningDone(AWaitParam);
    Inc(Result);
    end;
  end;
end;

{ TJobPool }

constructor TJobPool.Create(AMaxSize: Integer);
begin
inherited Create;
FSize := AMaxSize;
FLocker := TQSimpleLock.Create;
end;

destructor TJobPool.Destroy;
var
  AJob: PQJob;
begin
FLocker.Enter;
while FFirst <> nil do
  begin
  AJob := FFirst.Next;
  Dispose(FFirst);
  FFirst := AJob;
  end;
FreeObject(FLocker);
inherited;
end;

function TJobPool.Pop: PQJob;
begin
FLocker.Enter;
Result := FFirst;
if Result <> nil then
  begin
  FFirst := Result.Next;
  Dec(FCount);
  end;
FLocker.Leave;
if Result = nil then
  GetMem(Result, SizeOf(TQJob));
Result.Reset;
end;

procedure TJobPool.Push(AJob: PQJob);
var
  ADoFree: Boolean;
begin
{$IFDEF UNICODE}
if AJob.IsAnonWorkerProc then
  TQJobProcA(AJob.WorkerProc.ProcA) := nil{$IFNDEF NEXTGEN}; {$ENDIF}
{$ENDIF}
{$IFDEF NEXTGEN}
else
  PQJobProc(@AJob.WorkerProc)^ := nil;
{$ENDIF}
FLocker.Enter;
ADoFree := (FCount = FSize);
if not ADoFree then
  begin
  AJob.Next := FFirst;
  FFirst := AJob;
  Inc(FCount);
  end;
FLocker.Leave;
if ADoFree then
  begin
  FreeMem(AJob);
  end;
end;

{ TQSimpleLock }
{$IFDEF QWORKER_SIMPLE_LOCK}

constructor TQSimpleLock.Create;
begin
inherited;
FFlags := 0;
end;

procedure TQSimpleLock.Enter;
begin
while (AtomicOr(FFlags, $01) and $01) <> 0 do
  begin
  GiveupThread;
  end;
end;

procedure TQSimpleLock.Leave;
begin
AtomicAnd(FFlags, Integer($FFFFFFFE));
end;
{$ENDIF QWORKER_SIMPLE_JOB}
{ TQJobGroup }

function TQJobGroup.Add(AProc: TQJobProc; AData: Pointer;
  AInMainThread: Boolean; AFreeType: TQJobDataFreeType): Boolean;
var
  AJob: PQJob;
begin
AJob := InitGroupJob(AData, AInMainThread, AFreeType);
{$IFDEF NEXTGEN}
PQJobProc(@AJob.WorkerProc)^ := AProc;
{$ELSE}
AJob.WorkerProc.Proc := AProc;
{$ENDIF}
Result := InternalAddJob(AJob);
end;

function TQJobGroup.Add(AProc: TQJobProcG; AData: Pointer;
  AInMainThread: Boolean; AFreeType: TQJobDataFreeType): Boolean;
begin
Result := Add(MakeJobProc(AProc), AData, AInMainThread, AFreeType);
end;
{$IFDEF UNICODE}

function TQJobGroup.Add(AProc: TQJobProcA; AData: Pointer;
  AInMainThread: Boolean; AFreeType: TQJobDataFreeType): Boolean;
var
  AJob: PQJob;
begin
AJob := InitGroupJob(AData, AInMainThread, AFreeType);
TQJobProcA(AJob.WorkerProc.ProcA) := AProc;
Result := InternalAddJob(AJob);
end;
{$ENDIF}

procedure TQJobGroup.Cancel(AWaitRunningDone: Boolean);
var
  I: Integer;
  AJob: PQJob;
  AWaitParam: TWorkerWaitParam;
begin
FLocker.Enter;
try
  if FByOrder then
    begin
    I := 0;
    while I < FItems.Count do
      begin
      AJob := FItems[I];
      if AJob.PopTime = 0 then
        begin
        Workers.FreeJob(AJob);
        FItems.Delete(I);
        end
      else
        Inc(I);
      end;
    end;
  FItems.Clear;
finally
  FLocker.Leave;
end;
if FPosted <> 0 then
  begin
  Dec(FPosted,Workers.FSimpleJobs.Clear(Self,MaxInt));
  if AWaitRunningDone then
    begin
    AWaitParam.WaitType := 3;
    AWaitParam.Group := Self;
    Workers.WaitRunningDone(AWaitParam);
    end;
  end;
if FPosted = 0 then
  FEvent.SetEvent;
end;

constructor TQJobGroup.Create(AByOrder: Boolean);
begin
inherited Create;
FEvent := TEvent.Create(nil, False, False, '');
FLocker := TQSimpleLock.Create;
FByOrder := AByOrder;
FItems := TQJobItemList.Create;
end;

destructor TQJobGroup.Destroy;
var
  I: Integer;
begin
Cancel;
if FTimeoutCheck then
  Workers.Clear(Self, 1);
FLocker.Enter;
try
  if FItems.Count > 0 then
    begin
    FWaitResult := wrAbandoned;
    FEvent.SetEvent;
    for I := 0 to FItems.Count - 1 do
      begin
      if PQJob(FItems[I]).PushTime <> 0 then
        JobPool.Push(FItems[I]);
      end;
    FItems.Clear;
    end;
finally
  FLocker.Leave;
end;
FreeObject(FLocker);
FreeObject(FEvent);
FreeObject(FItems);
inherited;
end;

procedure TQJobGroup.DoAfterDone;
begin
try
  if Assigned(FAfterDone) then
    FAfterDone(Self);
finally
  if FFreeAfterDone then
    begin
    FreeObject(Self);
    end;
end;
end;

procedure TQJobGroup.DoJobExecuted(AJob: PQJob);
var
  I: Integer;
  AIsDone: Boolean;
begin
AtomicIncrement(FRuns);
if FWaitResult = wrIOCompletion then
  begin
  AIsDone := False;
  FLocker.Enter;
  try
    I := FItems.IndexOf(AJob);
    if I <> -1 then
      begin
      FItems.Delete(I);
      if FItems.Count = 0 then
        begin
        AtomicDecrement(FPosted);
        FWaitResult := wrSignaled;
        FEvent.SetEvent;
        AIsDone := True;
        end
      else if ByOrder then
        begin
        if Workers.Post(FItems[0]) = 0 then
          begin
          AtomicDecrement(FPosted);
          FItems.Delete(0); // 投寄失败时，Post自动释放了作业
          FWaitResult := wrAbandoned;
          FEvent.SetEvent;
          AIsDone := True;
          end
        end
      else
        AtomicDecrement(FPosted);
      end;
  finally
    FLocker.Leave;
  end;
  if AIsDone then
    DoAfterDone;
  end;
end;

procedure TQJobGroup.DoJobsTimeout(AJob: PQJob);
begin
FTimeoutCheck := False;
Cancel;
if FWaitResult = wrIOCompletion then
  begin
  FWaitResult := wrTimeout;
  FEvent.SetEvent;
  DoAfterDone;
  end;
end;

function TQJobGroup.GetCount: Integer;
begin
Result := FItems.Count;
end;

function TQJobGroup.InitGroupJob(AData: Pointer; AInMainThread: Boolean;
  AFreeType: TQJobDataFreeType): PQJob;
begin
Result := JobPool.Pop;
JobInitialize(Result, AData, AFreeType, True, AInMainThread);
Result.Group := Self;
Result.SetFlags(JOB_GROUPED, True);
end;

function TQJobGroup.Insert(AIndex:Integer;AProc: TQJobProc; AData: Pointer;
  AInMainThread: Boolean; AFreeType: TQJobDataFreeType): Boolean;
var
  AJob: PQJob;
begin
AJob := InitGroupJob(AData, AInMainThread, AFreeType);
{$IFDEF NEXTGEN}
PQJobProc(@AJob.WorkerProc.Proc)^:= AProc;
{$ELSE}
AJob.WorkerProc.Proc:=AProc;
{$ENDIF}
Result := InternalInsertJob(AIndex,AJob);
end;

function TQJobGroup.Insert(AIndex:Integer;AProc: TQJobProcG; AData: Pointer;
  AInMainThread: Boolean; AFreeType: TQJobDataFreeType): Boolean;
var
  AJob: PQJob;
begin
AJob := InitGroupJob(AData, AInMainThread, AFreeType);
AJob.WorkerProc.ProcG:= AProc;
Result := InternalInsertJob(AIndex,AJob);
end;
{$IFDEF UNICODE}
function TQJobGroup.Insert(AIndex:Integer;AProc: TQJobProcA; AData: Pointer;
  AInMainThread: Boolean; AFreeType: TQJobDataFreeType): Boolean;
var
  AJob: PQJob;
begin
AJob := InitGroupJob(AData, AInMainThread, AFreeType);
TQJobProcA(AJob.WorkerProc.ProcA) := AProc;
Result := InternalInsertJob(AIndex,AJob);
end;
{$ENDIF}
function TQJobGroup.InternalAddJob(AJob: PQJob): Boolean;
begin
FLocker.Enter;
try
  FWaitResult := wrIOCompletion;
  if FPrepareCount > 0 then // 正在添加项目，加到列表中，等待Run
    begin
    FItems.Add(AJob);
    Result := True;
    end
  else
    begin
    if ByOrder then // 按顺序
      begin
      Result := True;
      FItems.Add(AJob);
      if FItems.Count = 1 then
        Result := Workers.Post(AJob) <> 0;
      end
    else
      begin
      Result := Workers.Post(AJob) <> 0;
      if Result then
        FItems.Add(AJob);
      end;
    if Result then
      AtomicIncrement(FPosted);
    end;
finally
  FLocker.Leave;
end;
end;

function TQJobGroup.InternalInsertJob(AIndex: Integer;AJob: PQJob): Boolean;
begin
FLocker.Enter;
try
  FWaitResult := wrIOCompletion;
  if AIndex>FItems.Count then
    AIndex:=FItems.Count
  else if AIndex<0 then
    AIndex:=0;
  if FPrepareCount > 0 then // 正在添加项目，加到列表中，等待Run
    begin
    FItems.Insert(AIndex,AJob);
    Result := True;
    end
  else
    begin
    if ByOrder then // 按顺序
      begin
      Result := True;
      FItems.Insert(AIndex,AJob);
      if FItems.Count = 1 then
        Result := Workers.Post(AJob) <> 0;
      end
    else //不按顺序触发时，其等价于Add
      begin
      Result := Workers.Post(AJob) <> 0;
      if Result then
        FItems.Add(AJob);
      end;
    if Result then
      AtomicIncrement(FPosted);
    end;
finally
  FLocker.Leave;
end;
end;

function TQJobGroup.MsgWaitFor(ATimeout: Cardinal): TWaitResult;
var
  AEmpty: Boolean;
begin
Result := FWaitResult;
if GetCurrentThreadId <> MainThreadId then
  Result := WaitFor(ATimeout)
else
  begin
  FLocker.Enter;
  try
    AEmpty := FItems.Count = 0;
    if AEmpty then
      Result := wrSignaled;
  finally
    FLocker.Leave;
  end;
  if Result = wrIOCompletion then
    begin
    if MsgWaitForEvent(FEvent, ATimeout) = wrSignaled then
      Result := FWaitResult;
    if Result = wrIOCompletion then
      begin
      Cancel;
      if Result = wrIOCompletion then
        Result := wrTimeout;
      end;
    if FTimeoutCheck then
      Workers.Clear(Self);
    if Result = wrTimeout then
      DoAfterDone;
    end
  else if AEmpty then
    DoAfterDone;
  end;
end;

procedure TQJobGroup.Prepare;
begin
AtomicIncrement(FPrepareCount);
end;

procedure TQJobGroup.Run(ATimeout: Cardinal);
var
  I: Integer;
  AJob: PQJob;
begin
if AtomicDecrement(FPrepareCount) = 0 then
  begin
  if ATimeout <> INFINITE then
    begin
    FTimeoutCheck := True;
    Workers.Delay(DoJobsTimeout, ATimeout * 10, nil);
    end;
  FLocker.Enter;
  try
    if FItems.Count = 0 then
      FWaitResult := wrSignaled
    else
      begin
      FWaitResult := wrIOCompletion;
      if ByOrder then
        begin
        AJob := FItems[0];
        if (AJob.PushTime = 0) then
          begin
          if Workers.Post(AJob) = 0 then
            FWaitResult := wrAbandoned
          else
            AtomicIncrement(FPosted);
          end;
        end
      else
        begin
        for I := 0 to FItems.Count - 1 do
          begin
          AJob := FItems[I];
          if AJob.PushTime = 0 then
            begin
            if Workers.Post(AJob) = 0 then
              begin
              FWaitResult := wrAbandoned;
              Break;
              end
            else
              AtomicIncrement(FPosted);
            end;
          end;
        end;
      end;
  finally
    FLocker.Leave;
  end;
  if FWaitResult <> wrIOCompletion then
    DoAfterDone;
  end;
end;

function TQJobGroup.WaitFor(ATimeout: Cardinal): TWaitResult;
var
  AEmpty: Boolean;
begin
Result := FWaitResult;
FLocker.Enter;
try
  AEmpty := FItems.Count = 0;
  if AEmpty then
    Result := wrSignaled;
finally
  FLocker.Leave;
end;
if Result = wrIOCompletion then
  begin
  if FEvent.WaitFor(ATimeout) = wrSignaled then
    Result := FWaitResult
  else
    begin
    Result := wrTimeout;
    Cancel;
    end;
  if Result = wrTimeout then
    DoAfterDone;
  end;
if FTimeoutCheck then
  Workers.Clear;
if AEmpty then
  DoAfterDone;
end;

function JobPoolCount: NativeInt;
begin
Result := JobPool.Count;
end;

function JobPoolPrint: QStringW;
var
  AJob: PQJob;
  ABuilder: TQStringCatHelperW;
begin
ABuilder := TQStringCatHelperW.Create;
JobPool.FLocker.Enter;
try
  AJob := JobPool.FFirst;
  while AJob <> nil do
    begin
    ABuilder.Cat(IntToHex(NativeInt(AJob), SizeOf(NativeInt))).Cat(SLineBreak);
    AJob := AJob.Next;
    end;
finally
  JobPool.FLocker.Leave;
  Result := ABuilder.Value;
  FreeObject(ABuilder);
end;
end;

{ TQForJobs }
procedure TQForJobs.BreakIt;
begin
AtomicExchange(FBreaked, 1);
end;

constructor TQForJobs.Create(const AStartIndex, AStopIndex: TForLoopIndexType;
  AData: Pointer; AFreeType: TQJobDataFreeType);
var
  ACount: NativeInt;
begin
inherited Create;
FIterator := AStartIndex - 1;
FStartIndex := AStartIndex;
FStopIndex := AStopIndex;
FWorkerCount := GetCPUCount;
ACount := (AStopIndex - AStartIndex) + 1;
if FWorkerCount > ACount then
  FWorkerCount := ACount;
FWorkJob := JobPool.Pop;
JobInitialize(FWorkJob, AData, AFreeType, True, False);
FEvent := TEvent.Create();
end;

destructor TQForJobs.Destroy;
begin
Workers.FreeJob(FWorkJob);
FreeObject(FEvent);
inherited;
end;

procedure TQForJobs.DoJob(AJob: PQJob);
var
  I: NativeInt;
begin
try
  repeat
    I := AtomicIncrement(FIterator);
    if I <= StopIndex then
      begin
{$IFDEF UNICODE}
      if FWorkJob.IsAnonWorkerProc then
        TQForJobProcA(FWorkJob.WorkerProc.ForProcA)(Self, FWorkJob, I)
      else
{$ENDIF}
        if FWorkJob.WorkerProc.Data = nil then
          FWorkJob.WorkerProc.ForProcG(Self, FWorkJob, I)
        else
          PQForJobProc(@FWorkJob.WorkerProc)^(Self, FWorkJob, I);
      AtomicIncrement(FWorkJob.Runs);
      end
    else
      Break;
  until (FIterator > StopIndex) or (FBreaked <> 0) or (AJob.IsTerminated);
except
  on E: Exception do
end;
if AJob.IsTerminated then
  BreakIt;
if AtomicDecrement(FWorkerCount) = 0 then
  FEvent.SetEvent;
end;
{$IFDEF UNICODE}

class function TQForJobs.&For(const AStartIndex, AStopIndex: TForLoopIndexType;
  AWorkerProc: TQForJobProcA; AMsgWait: Boolean; AData: Pointer;
  AFreeType: TQJobDataFreeType): TWaitResult;
var
  AInst: TQForJobs;
begin
AInst := TQForJobs.Create(AStartIndex, AStopIndex, AData, AFreeType);
try
  TQForJobProcA(AInst.FWorkJob.WorkerProc.ForProcA) := AWorkerProc;
  AInst.FWorkJob.IsAnonWorkerProc := True;
  AInst.Start;
  Result := AInst.Wait(AMsgWait);
finally
  FreeObject(AInst);
end;
end;
{$ENDIF}

class function TQForJobs.&For(const AStartIndex, AStopIndex: TForLoopIndexType;
  AWorkerProc: TQForJobProcG; AMsgWait: Boolean; AData: Pointer;
  AFreeType: TQJobDataFreeType): TWaitResult;
var
  AInst: TQForJobs;
begin
AInst := TQForJobs.Create(AStartIndex, AStopIndex, AData, AFreeType);
try
  AInst.FWorkJob.WorkerProc.ForProcG := AWorkerProc;
  AInst.Start;
  Result := AInst.Wait(AMsgWait);
finally
  FreeObject(AInst);
end;
end;

class function TQForJobs.&For(const AStartIndex, AStopIndex: TForLoopIndexType;
  AWorkerProc: TQForJobProc; AMsgWait: Boolean; AData: Pointer;
  AFreeType: TQJobDataFreeType): TWaitResult;
var
  AInst: TQForJobs;
begin
AInst := TQForJobs.Create(AStartIndex, AStopIndex, AData, AFreeType);
try
  PQForJobProc(@AInst.FWorkJob.WorkerProc)^ := AWorkerProc;
  AInst.Start;
  Result := AInst.Wait(AMsgWait);
finally
  FreeObject(AInst);
end;
end;

function TQForJobs.GetAvgTime: Cardinal;
begin
if Runs > 0 then
  Result := TotalTime div Runs
else
  Result := 0;
end;

function TQForJobs.GetBreaked: Boolean;
begin
Result := FBreaked <> 0;
end;

function TQForJobs.GetRuns: Cardinal;
begin
Result := FWorkJob.Runs;
end;

function TQForJobs.GetTotalTime: Cardinal;
begin
Result := FWorkJob.TotalUsedTime;
end;

procedure TQForJobs.Start;
var
  I: Integer;
begin
FWorkJob.StartTime := GetTimestamp;
Workers.DisableWorkers;
for I := 0 to FWorkerCount - 1 do
  Workers.Post(DoJob, nil);
Workers.EnableWorkers;
end;

function TQForJobs.Wait(AMsgWait: Boolean): TWaitResult;
begin
if FWorkerCount > 0 then
  begin
  if AMsgWait then
    Result := MsgWaitForEvent(FEvent, INFINITE)
  else
    Result := FEvent.WaitFor(INFINITE);
  if FBreaked <> 0 then
    Result := wrAbandoned;
  end
else
  Result := wrSignaled;
FWorkJob.TotalUsedTime := GetTimestamp - FWorkJob.StartTime;
end;

{ TStaticThread }

procedure TStaticThread.CheckNeeded;
begin
FEvent.SetEvent;
end;

constructor TStaticThread.Create;
begin
inherited Create(True);
FEvent := TEvent.Create(nil, False, False, '');
{$IFDEF MSWINDOWS}
Priority := tpIdle;
{$ENDIF}
end;

destructor TStaticThread.Destroy;
begin
FreeObject(FEvent);
inherited;
end;

procedure TStaticThread.Execute;
var
  ATimeout: Cardinal;
  // 计算末1秒的CPU占用率，如果低于60%且有未处理的作业，则启动更多的工作者来完成作业
  function LastCpuUsage: Integer;
{$IFDEF MSWINDOWS}
  var
    CurSystemTimes: TSystemTimes;
    Usage, Idle: UInt64;
{$ENDIF}
  begin
{$IFDEF MSWINDOWS}
  Result := 0;
  if WinGetSystemTimes(PFileTime(@CurSystemTimes.IdleTime)^,
    PFileTime(@CurSystemTimes.KernelTime)^, PFileTime(@CurSystemTimes.UserTime)^)
  then
    begin
    Usage := (CurSystemTimes.UserTime - FLastTimes.UserTime) +
      (CurSystemTimes.KernelTime - FLastTimes.KernelTime) +
      (CurSystemTimes.NiceTime - FLastTimes.NiceTime);
    Idle := CurSystemTimes.IdleTime - FLastTimes.IdleTime;
    if Usage > Idle then
      Result := (Usage - Idle) * 100 div Usage;
    FLastTimes := CurSystemTimes;
    end;
{$ELSE}
  Result := TThread.GetCPUUsage(FLastTimes);
{$ENDIF}
  end;

begin
{$IFDEF MSWINDOWS}
{$IFDEF UNICODE}
NameThreadForDebugging('QStaticThread');
{$ENDIF}
if Assigned(WinGetSystemTimes) then // Win2000/XP<SP2该函数未定义，不能使用
  ATimeout := 1000
else
  ATimeout := INFINITE;
{$ELSE}
ATimeout := 1000;
{$ENDIF}
while not Terminated do
  begin
  case FEvent.WaitFor(ATimeout) of
    wrSignaled:
      begin
      if Assigned(Workers) and (not Workers.Terminating) and (Workers.IdleWorkers = 0) then
        Workers.LookupIdleWorker(False);
      end;
    wrTimeout:
      begin
      if Assigned(Workers) and (not Workers.Terminating) and Assigned(Workers.FSimpleJobs) and (Workers.FSimpleJobs.Count > 0) and
        (LastCpuUsage < 60) and (Workers.IdleWorkers = 0) then
        Workers.LookupIdleWorker(True);
      end;
  end;
  end;
Workers.FStaticThread := nil;
end;

{ TQJobExtData }

constructor TQJobExtData.Create(AData: Pointer; AOnFree: TQExtFreeEvent);
begin
inherited Create;
FOrigin := AData;
FOnFree := AOnFree;
end;

constructor TQJobExtData.Create(const S: QStringW);
var
  D: PQStringW;
begin
New(D);
D^ := S;
Create(D, DoFreeAsString);
end;
{$IFNDEF NEXTGEN}

constructor TQJobExtData.Create(const S: AnsiString);
var
  D: PAnsiString;
begin
New(D);
D^ := S;
Create(D, DoFreeAsAnsiString);
end;
{$ENDIF}

constructor TQJobExtData.Create(const Value: Integer);
begin
FOrigin := Pointer(Value);
inherited Create;
end;

constructor TQJobExtData.Create(const Value: Int64);
{$IFDEF CPUX64}
begin
FOrigin := Pointer(Value);
inherited Create;
{$ELSE}
var
  D: PInt64;
begin
GetMem(D, SizeOf(Int64));
D^ := Value;
Create(D, DoSimpleTypeFree);
{$ENDIF}
end;

constructor TQJobExtData.Create(const Value: Boolean);
begin
FOrigin := Pointer(Integer(Value));
inherited Create;
end;

constructor TQJobExtData.Create(const Value: Double);
var
  D: PDouble;
begin
GetMem(D, SizeOf(Double));
D^ := Value;
Create(D, DoSimpleTypeFree);
end;

constructor TQJobExtData.CreateAsDateTime(const Value: TDateTime);
begin
Create(Value);
end;

{$IFDEF UNICODE}

constructor TQJobExtData.Create(AOnInit: TQExtInitEventA;
  AOnFree: TQExtFreeEventA);
begin
FOnFreeA := AOnFree;
if Assigned(AOnInit) then
  AOnInit(FOrigin);
inherited Create;
end;
{$ENDIF}

constructor TQJobExtData.Create(AOnInit: TQExtInitEvent;
  AOnFree: TQExtFreeEvent);
begin
FOnFree := AOnFree;
if Assigned(AOnInit) then
  AOnInit(FOrigin);
inherited Create;
end;

{$IFDEF UNICODE}

constructor TQJobExtData.Create(AData: Pointer; AOnFree: TQExtFreeEventA);
begin
inherited Create;
FOrigin := AData;
FOnFreeA := AOnFree;
end;
{$ENDIF}

destructor TQJobExtData.Destroy;
begin
if Assigned(Origin) then
  begin
{$IFDEF UNICODE}
  if Assigned(FOnFreeA) then
    FOnFreeA(Origin);
{$ENDIF}
  if Assigned(FOnFree) then
    FOnFree(Origin);
  end;
inherited;
end;
{$IFNDEF NEXTGEN}

procedure TQJobExtData.DoFreeAsAnsiString(AData: Pointer);
begin
Dispose(PAnsiString(AData));
end;
{$ENDIF}

procedure TQJobExtData.DoFreeAsString(AData: Pointer);
begin
Dispose(PQStringW(AData));
end;

procedure TQJobExtData.DoSimpleTypeFree(AData: Pointer);
begin
FreeMem(AData);
end;
{$IFNDEF NEXTGEN}

function TQJobExtData.GetAsAnsiString: AnsiString;
begin
Result := PAnsiString(Origin)^;
end;
{$ENDIF}

function TQJobExtData.GetAsBoolean: Boolean;
begin
Result := Origin <> nil;
end;

function TQJobExtData.GetAsDateTime: TDateTime;
begin
Result := PDateTime(Origin)^;
end;

function TQJobExtData.GetAsDouble: Double;
begin
Result := PDouble(Origin)^;
end;

function TQJobExtData.GetAsInt64: Int64;
begin
Result := PInt64(Origin)^;
end;

function TQJobExtData.GetAsInteger: Integer;
begin
Result := Integer(Origin);
end;

function TQJobExtData.GetAsString: QStringW;
begin
Result := PQStringW(Origin)^;
end;
{$IFNDEF NEXTGEN}

procedure TQJobExtData.SetAsAnsiString(const Value: AnsiString);
begin
PAnsiString(Origin)^ := Value;
end;
{$ENDIF}

procedure TQJobExtData.SetAsBoolean(const Value: Boolean);
begin
FOrigin := Pointer(Integer(Value));
end;

procedure TQJobExtData.SetAsDateTime(const Value: TDateTime);
begin
PDateTime(Origin)^ := Value;
end;

procedure TQJobExtData.SetAsDouble(const Value: Double);
begin
PDouble(Origin)^ := Value;
end;

procedure TQJobExtData.SetAsInt64(const Value: Int64);
begin
{$IFDEF CPUX64}
FOrigin := Pointer(Value);
{$ELSE}
PInt64(FOrigin)^ := Value;
{$ENDIF}
end;

procedure TQJobExtData.SetAsInteger(const Value: Integer);
begin
FOrigin := Pointer(Value);
end;

procedure TQJobExtData.SetAsString(const Value: QStringW);
begin
PQStringW(FOrigin)^ := Value;
end;

procedure RunInMainThread(AProc:TMainThreadProc;AData:Pointer);overload;
var
  AHelper:TRunInMainThreadHelper;
begin
AHelper:=TRunInMainThreadHelper.Create;
AHelper.FProc:=AProc;
AHelper.FData:=AData;
try
  TThread.Synchronize(nil,AHelper.Execute);
finally
  FreeObject(AHelper);
end;
end;
procedure RunInMainThread(AProc:TMainThreadProcG;AData:Pointer);overload;
var
  AHelper:TRunInMainThreadHelper;
begin
AHelper:=TRunInMainThreadHelper.Create;
TMethod(AHelper.FProc).Code:=@AProc;
TMethod(AHelper.FProc).Data:=nil;
AHelper.FData:=AData;
try
  TThread.Synchronize(nil,AHelper.Execute);
finally
  FreeObject(AHelper);
end;
end;
{$IFDEF UNICODE}
procedure RunInMainThread(AProc:TThreadProcedure);overload;
begin
TThread.Synchronize(nil,AProc);
end;
{$ENDIF}
{ TRunInMainThreadHelper }

procedure TRunInMainThreadHelper.Execute;
begin
FProc(FData);
end;

initialization

GetThreadStackInfo := nil;
{$IFDEF MSWINDOWS}
GetTickCount64 := GetProcAddress(GetModuleHandle(kernel32), 'GetTickCount64');
WinGetSystemTimes := GetProcAddress(GetModuleHandle(kernel32),
  'GetSystemTimes');
if not QueryPerformanceFrequency(_PerfFreq) then
  _PerfFreq := -1;
{$ELSE}
_Watch := TStopWatch.Create;
_Watch.Start;
{$ENDIF}
_CPUCount := GetCPUCount;
JobPool := TJobPool.Create(1024);
Workers := TQWorkers.Create;

finalization

FreeObject(Workers);
FreeObject(JobPool);

end.
