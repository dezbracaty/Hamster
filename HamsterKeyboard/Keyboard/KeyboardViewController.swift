#if os(iOS)
import Combine
import Foundation
import KeyboardKit
import LibrimeKit
import UIKit

// 全局变量: 设置Rime是否首次启动标志
var isRimeFirstRun = true
// let globalRimeEngine = RimeEngine()
// let globalAppSettings = HamsterAppSettings()

// Hamster键盘Controller
open class HamsterKeyboardViewController: KeyboardInputViewController {
  private let log = Logger.shared.log
  public var rimeEngine = RimeEngine()
  public var appSettings = HamsterAppSettings()
  var cancellables = Set<AnyCancellable>()
  lazy var hamsterInputSetProvider: HamsterInputSetProvider = .init(keyboardContext: keyboardContext)
  
  override public func viewDidLoad() {
    self.log.info("viewDidLoad() begin")
    // 注意初始化的顺序
    
    // TODO: 动态设置 local
    self.keyboardContext.locale = Locale(identifier: "zh-Hans")
//    self.log.info("local language: \(Locale.preferredLanguages[0])")
//    self.log.info("local language: \(Locale.autoupdatingCurrent.identifier)")
//    self.log.info("local language: \(Locale.autoupdatingCurrent.languageCode)")
//    self.log.info("local language: \(Locale.current.identifier)")
//    self.log.info("local language: \(Locale.current.languageCode)")
    
    // 外观
    self.keyboardAppearance = HamsterKeyboardAppearance(
      keyboardContext: self.keyboardContext,
      rimeEngine: self.rimeEngine,
      appSettings: self.appSettings
    )
    // 布局
    self.keyboardLayoutProvider = HamsterStandardKeyboardLayoutProvider(
      keyboardContext: self.keyboardContext,
      inputSetProvider: self.hamsterInputSetProvider,
      appSettings: self.appSettings
    )
    self.keyboardBehavior = HamsterKeyboardBehavior(keyboardContext: self.keyboardContext)
    // TODO: 长按按钮设置
    self.calloutActionProvider = HamsterCalloutActionProvider(
      keyboardContext: self.keyboardContext,
      rimeEngine: self.rimeEngine
    )
    // 键盘反馈设置
    self.keyboardFeedbackSettings = KeyboardFeedbackSettings(
      audioConfiguration: AudioFeedbackConfiguration(),
      hapticConfiguration: HapticFeedbackConfiguration()
    )
    self.keyboardFeedbackHandler = HamsterKeyboardFeedbackHandler(
      settings: self.keyboardFeedbackSettings,
      appSettings: self.appSettings
    )
    // 键盘Action处理
    self.keyboardActionHandler = HamsterKeyboardActionHandler(
      inputViewController: self,
      keyboardContext: self.keyboardContext,
      keyboardFeedbackHandler: self.keyboardFeedbackHandler
    )
    
    self.calloutContext = KeyboardCalloutContext(
      action: HamsterActionCalloutContext(
        actionHandler: keyboardActionHandler,
        actionProvider: calloutActionProvider
      ),
      input: InputCalloutContext(
        isEnabled: UIDevice.current.userInterfaceIdiom == .phone
      )
    )
    
    self.setupRimeEngine()
    self.setupAppSettings()
    
    super.viewDidLoad()
  }
  
  override public func viewWillSetupKeyboard() {
    self.log.debug("viewWillSetupKeyboard() begin")
    let alphabetKeyboard = AlphabetKeyboard(keyboardInputViewController: self)
      .environmentObject(self.rimeEngine)
      .environmentObject(self.appSettings)
    setup(with: alphabetKeyboard)
  }
  
  override public func viewDidDisappear(_ animated: Bool) {
    self.log.debug("HamsterKeyboardViewController viewDidDisappear")
  }
  
  public func dealloc() {
    self.log.debug("HamsterKeyboardViewController dealloc")
    self.rimeEngine.shutdownRime()
  }
  
  private func setupAppSettings() {
    // 按键气泡
    self.appSettings.$showKeyPressBubble
      .receive(on: RunLoop.main)
      .sink { [weak self] in
        guard let self = self else { return }
        self.log.info("combine $showKeyPressBubble \($0)")
        self.calloutContext.input.isEnabled = $0
      }
      .store(in: &self.cancellables)
    
    // 候选字最大数量
    self.appSettings.$rimeMaxCandidateSize
      .receive(on: RunLoop.main)
      .sink { [weak self] rimeMaxCandidateSize in
        guard let self = self else { return }
        self.log.info("combine $rimeMaxCandidateSize: \(rimeMaxCandidateSize)")
        self.rimeEngine.maxCandidateCount = rimeMaxCandidateSize
      }
      .store(in: &self.cancellables)
    
    // 输入方案变更
    self.appSettings.$rimeInputSchema
      .receive(on: RunLoop.main)
      .sink { [weak self] schemaName in
        guard let self = self else { return }
        // 设置用户选择方案
        let setSchemaHandled = self.rimeEngine.setSchema(schemaName)
        Logger.shared.log.debug("combine $rimeInputSchema:  \(schemaName), setSchemaHandled: \(setSchemaHandled)")
      }
      .store(in: &self.cancellables)
    
    // 配色方案变更
    self.appSettings.$enableRimeColorSchema
      .combineLatest(self.appSettings.$rimeColorSchema)
      .receive(on: RunLoop.main)
      .sink { [weak self] enable, schemaName in
        guard let self = self else { return }
        self.log.info("combine $enableRimeColorSchema and $rimeInputSchema: \(enable), \(schemaName)")
        if enable {
          self.rimeEngine.currentColorSchema = self.getCurrentColorSchema()
        }
      }
      .store(in: &self.cancellables)
  }
  
  private func setupRimeEngine() {
    do {
      try RimeEngine.syncAppGroupSharedSupportDirectory(override: self.appSettings.rimeNeedOverrideUserDataDirectory)
      try RimeEngine.initUserDataDirectory()
      try RimeEngine.syncAppGroupUserDataDirectory(override: self.appSettings.rimeNeedOverrideUserDataDirectory)
    } catch {
      self.log.error("create rime directory error: \(error), \(error.localizedDescription)")
    }
    
    let traits = self.rimeEngine.createTraits(
      sharedSupportDir: RimeEngine.sharedSupportDirectory.path,
      userDataDir: RimeEngine.userDataDirectory.path
    )
    
    // setupRime不能重复调用, 否则会触发panic
    // utilities.cc:365] Check failed: !IsGoogleLoggingInitialized() You called InitGoogleLogging() twice!
    // rimeEngine是ViewController的成员变量, 每次启动都会被初始化
    // 所以内部的是否首次启动标志不起作用, 这里在ViewController外部定义了全局变量, 用来标记是否首次启动.
    if isRimeFirstRun {
      isRimeFirstRun = false
      self.rimeEngine.setupRime(traits)
    }
    self.rimeEngine.startRime(traits, fullCheck: self.appSettings.rimeNeedOverrideUserDataDirectory)
    if self.appSettings.rimeNeedOverrideUserDataDirectory {
      self.appSettings.rimeNeedOverrideUserDataDirectory = false
    }
    self.rimeEngine.createSession()
    self.rimeEngine.maxCandidateCount = self.appSettings.rimeMaxCandidateSize
    self.rimeEngine.reset()
  }
  
  // MARK: - KeyboardController

  override open func insertText(_ text: String) {
    // 是否英文模式
    if self.rimeEngine.isAsciiMode() {
      textDocumentProxy.insertText(text)
      return
    }
    
    // 调用输入法引擎
    self.inputCharacter(key: text)
  }
  
  override open func deleteBackward() {
    self.inputRimeKeycode(keycode: XK_BackSpace)
  }

  override open func setKeyboardType(_ type: KeyboardType) {
    // TODO: 添加shift通配符功能
    keyboardContext.keyboardType = type
  }
}

extension HamsterKeyboardViewController {
  // 简繁切换
  func switchTraditionalSimplifiedChinese() {
    self.rimeEngine.simplifiedChineseMode.toggle()
    _ = self.rimeEngine.simplifiedChineseMode(self.rimeEngine.simplifiedChineseMode)
  }
  
  // 中英切换
  func switchEnglishChinese() {
    self.rimeEngine.asciiMode.toggle()
  }
  
  /// 次选上屏
  func secondCandidateTextOnScreen() -> Bool {
    let status = self.rimeEngine.status()
    if status.isComposing {
      let candidates = self.rimeEngine.suggestions
      if candidates.isEmpty {
        return false
      }
      if candidates.count >= 2 {
        self.textDocumentProxy.insertText(candidates[1].text)
        self.rimeEngine.reset()
        return true
      }
    }
    return false
  }
  
  /// 首选候选字上屏
  func candidateTextOnScreen() -> Bool {
    let status = self.rimeEngine.status()
    if status.isComposing {
      let candidates = self.rimeEngine.suggestions
      if candidates.isEmpty {
        return false
      }
      self.textDocumentProxy.insertText(candidates[0].text)
      self.rimeEngine.reset()
      return true
    }
    return false
  }
  
  // 光标移动句首
  func moveBeginOfSentence() {
    if let beforInput = self.textDocumentProxy.documentContextBeforeInput {
      if let lastIndex = beforInput.lastIndex(of: "\n") {
        let offset = beforInput[lastIndex ..< beforInput.endIndex].count - 1
        if offset > 0 {
          self.textDocumentProxy.adjustTextPosition(byCharacterOffset: -offset)
        }
      } else {
        self.textDocumentProxy.adjustTextPosition(byCharacterOffset: -beforInput.count)
      }
    }
  }
  
  // 光标移动句尾
  func moveEndOfSentence() {
    let offset = self.textDocumentProxy.documentContextAfterInput?.count ?? 0
    if offset > 0 {
      self.textDocumentProxy.adjustTextPosition(byCharacterOffset: offset)
    }
  }
  
  // 候选字上一页
  func previousPageOfCandidates() {
    if self.rimeEngine.inputKeyCode(XK_Page_Up) {
      self.rimeEngine.contextReact()
    } else {
      Logger.shared.log.warning("rime input pageup result error")
    }
  }
  
  // 候选字下一页
  func nextPageOfCandidates() {
    if self.rimeEngine.inputKeyCode(XK_Page_Down) {
      self.rimeEngine.contextReact()
    } else {
      Logger.shared.log.debug("rime input pageDown result error")
    }
  }
  
  // 当前颜色
  func getCurrentColorSchema() -> ColorSchema {
    Logger.shared.log.info("call getCurrentColorSchema()")
    let schema = ColorSchema()
    
    if !self.appSettings.enableRimeColorSchema {
      return schema
    }
    let name = self.appSettings.rimeColorSchema
    if name.isEmpty {
      return schema
    }
    guard let colorSchema = self.rimeEngine.colorSchema().first(where: { $0.schemaName == name }) else {
      return schema
    }
    Logger.shared.log.info("call getCurrentColorSchema, schameName = \(colorSchema.schemaName)")
    return colorSchema
  }
  
  // 修改输入方案
  func changeInputSchema(_ schema: String) {
    if !schema.isEmpty {
//      self.rimeEngine.needChangeInputSchema = true
//      self.rimeEngine.userInputSchemaName = schema
    }
  }
  
  /// 根据索引选择候选字
  func selectCandidateIndex(index: Int) {
    if self.rimeEngine.selectCandidate(index: index) {
      // 唯一码直接上屏
      let commitText = self.rimeEngine.getCommitText()
      if !commitText.isEmpty {
        self.textDocumentProxy.insertText(commitText)
      }
      
      // 查看输入法状态
      let status = self.rimeEngine.status()
      // 如不存在候选字,则重置输入法
      if !status.isComposing {
        self.rimeEngine.reset()
      } else {
        self.rimeEngine.contextReact()
      }
    }
  }
  
  /// 字符输入
  func inputCharacter(key: String) {
    let keyUTF8 = key.utf8
    if keyUTF8.count == 1, let first = keyUTF8.first {
      self.inputRimeKeycode(keycode: Int32(first))
    } else {
      self.textDocumentProxy.insertText(key)
    }
  }
  
  /// 转为RimeCode
  func inputRimeKeycode(keycode: Int32, modifier: Int32 = 0) {
    let handled = self.rimeEngine.inputKeyCode(keycode, modifier: modifier)
    if !handled {
      // 特殊功能键处理
      switch keycode {
      case XK_Return:
        self.textDocumentProxy.insertText(.newline)
        return
      case XK_BackSpace:
        self.textDocumentProxy.deleteBackward(range: keyboardBehavior.backspaceRange)
        return
      case XK_Tab:
        self.textDocumentProxy.insertText(.tab)
        return
      default:
        break
      }
    }
    
    // 唯一码直接上屏
    let commitText = self.rimeEngine.getCommitText()
    if !commitText.isEmpty {
      self.textDocumentProxy.insertText(commitText)
    }
      
    // 查看输入法状态
    let status = self.rimeEngine.status()
    // 如不存在候选字,则重置输入法
    if !status.isComposing {
      self.rimeEngine.reset()
    } else {
      self.rimeEngine.contextReact()
    }
    
    // 符号键直接上屏
    if !handled, let str = String(data: Data([UInt8(keycode)]), encoding: .utf8) {
      self.textDocumentProxy.insertText(String(str))
    }
  }
}
#endif
