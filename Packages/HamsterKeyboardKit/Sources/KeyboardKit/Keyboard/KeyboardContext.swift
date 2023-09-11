//
//  KeyboardContext.swift
//  KeyboardKit
//
//  Created by Daniel Saidi on 2020-06-15.
//  Copyright © 2020-2023 Daniel Saidi. All rights reserved.
//

import Combine
import Foundation
import HamsterKit
import HamsterModel
import OSLog
import UIKit

/**
 This class provides keyboard extensions with contextual and
 observable information about the keyboard extension itself.

 该类为键盘扩展提供有关键盘扩展本身的上下文和可观测信息。

 You can use ``locale`` to get and set the raw locale of the
 keyboard or use the various `setLocale(...)` functions that
 support using both `Locale` and ``KeyboardLocale``. You can
 use ``locales`` to set all the available locales, then call
 ``selectNextLocale()`` to select the next available locale.

 您可以使用 ``locale`` 获取和设置键盘的本地化信息， 或者使用各种同时支持使用 `Locale` 和 `KeyboardLocale` 的 `setLocale(...)` 函数。
 可以使用 ``locales`` 设置所有可用的本地化语言，然后调用 ``selectNextLocale()`` 选择下一个可用的本地化语言。

 KeyboardKit automatically creates an instance of this class
 and binds the created instance to the keyboard controller's
 ``KeyboardInputViewController/keyboardContext``.

 KeyboardKit 会自动创建该类的实例，并将创建的实例绑定到 Keyboard Controller 的 ``KeyboardInputViewController/keyboardContext`` 中。
 */
public class KeyboardContext: ObservableObject {
  /**
   The property can be set to override auto-capitalization
   information provided by ``autocapitalizationType``.

   设置该属性可覆盖 ``autocapitalizationType`` 提供的自动大写信息。
   */
  @Published
  public var autocapitalizationTypeOverride: KeyboardAutocapitalizationType?

  /**
   The device type that is currently used.

   当前使用的设备类型。

   By default, this is ``DeviceType/current``, but you can
   change it to anything you like.

   默认情况下，这是 ``DeviceType/current``'，但您可以随意更改。
   */
  @Published
  public var deviceType: DeviceType = .current

  /**
   Whether or not the input controller has a dictation key.

   是否有听写按键。
   */
  @Published
  public var hasDictationKey: Bool = false

  /**
   Whether or not the extension has been given full access.

   扩展程序是否已被授予完全访问权限。
   */
  @Published
  public var hasFullAccess: Bool = false

  /**
   The current interface orientation.

   当前界面的方向。
   */
  @Published
  public var interfaceOrientation: InterfaceOrientation = .portrait

  /**
   Whether or not auto-capitalization is enabled.

   是否启用自动大写。

   You can set this to `false` to override the behavior of
   the text document proxy.

   您可以将其设置为 "false"，以覆盖 text document proxy 的行为。
   */
  @Published
  public var isAutoCapitalizationEnabled = true

  /**
   Whether or not the keyboard is in floating mode.

   键盘是否处于浮动模式。
   */
  @Published
  public var isKeyboardFloating = false

  /**
   An optional dictation replacement action, which will be
   used by some ``KeyboardLayoutProvider`` implementations.

   可选的听写替换操作，某些 ``KeyboardLayoutProvider`` 实现将使用该操作。

   > Warning: This will be deprecated and not used anymore
   in KeyboardKit 7.9.9, then eventually removed in 8.0. A
   replacement is to use a custom ``KeyboardLayoutProvider``
   instead, which allows greater configuration options.

   > 警告：在 KeyboardKit 7.9.9 中将被废弃并不再使用，最终将在 8.0 中移除。
   > 取而代之的是使用自定义的 ``KeyboardLayoutProvider`` ，它允许更多的配置选项。
   */
  @Published
  public var keyboardDictationReplacement: KeyboardAction?

  /**
   The keyboard type that is currently used.

   当前使用的键盘类型。
   */
  @Published
//  public var keyboardType = KeyboardType.chinese(.lowercased)
  public var keyboardType = KeyboardType.chineseNineGrid

  /// 记录上一次的键盘类型, 用于返回
  public var lastKeyboardTypeStack: [KeyboardType] = []

  /**
   The locale that is currently being used.

   当前使用的本地语言。

   This uses `Locale` instead of ``KeyboardLocale``, since
   keyboards can use locales that are not in that enum.

   这将使用 `Locale` 而不是 `KeyboardLocale``，因为键盘可以使用不在该枚举中的本地语言。
   */
  @Published
  public var locale = Locale.current

  /**
   The locales that are currently enabled for the keyboard.

   键盘当前启用的本地语言列表。
   */
  @Published
  public var locales: [Locale] = [.current]

  /**
   An custom locale to use when displaying other locales.

   自定义本地语言，用于显示其他本地语言。

   If no locale is specified, the ``locale`` will be used.

   如果未指定 locale，则将使用 ``locale``。
   */
  @Published
  public var localePresentationLocale: Locale?

  /**
   Whether or not the keyboard should (must) have a switch
   key for selecting the next keyboard.

   键盘是否应该（必须）有用于选择下一个键盘的切换键。
   */
  @Published
  public var needsInputModeSwitchKey = false

  /**
   Whether or not the context prefers autocomplete.

   上下文是否偏好自动完成。

   The property is set every time the proxy syncs with the
   controller. You can ignore it if you want.

   proxy 每次与 controller 同步时都会设置该属性。如果需要，可以忽略它。
   */
  @Published
  public var prefersAutocomplete = true

  /**
   The primary language that is currently being used.

   目前使用的主要语言。
   */
  @Published
  public var primaryLanguage: String?

  /**
   The screen size, which is used by some library features.

   屏幕尺寸，用于某些 Library 功能。
   */
  @Published
  public var screenSize = CGSize.zero

  /**
   The space long press behavior to use.

   空格长按的行为。
   */
  @Published
  public var spaceLongPressBehavior = SpaceLongPressBehavior.moveInputCursor

  /**
   The main text document proxy.
   */
  @Published
  public var mainTextDocumentProxy: UITextDocumentProxy = PreviewTextDocumentProxy()

  /**
   The text document proxy that is currently active.

   当前激活的 text document proxy。
   */
  @Published
  public var textDocumentProxy: UITextDocumentProxy = PreviewTextDocumentProxy()

  /**
   The text input mode of the input controller.

   controler 的文本输入模式。
   */
  @Published
  public var textInputMode: UITextInputMode?

  /**
   The input controller's current trait collection.

   controller 的当前特质集合。
   */
  @Published
  public var traitCollection = UITraitCollection()

  /**
   仓输入法配置
   */
  public var hamsterConfig: HamsterConfiguration? = nil {
    didSet {
      cacheHamsterKeyboardColor = nil
    }
  }

  /// 输入法配色方案缓存
  /// 为计算属性 `hamsterKeyboardColor` 提供缓存
  private var cacheHamsterKeyboardColor: HamsterModel.KeyboardColor?

  /// 候选区域状态
  @Published
  public var candidatesViewState: CandidateWordsView.State = .collapse
  public var candidatesViewStatePublished: AnyPublisher<CandidateWordsView.State, Never> {
    $candidatesViewState.eraseToAnyPublisher()
  }

  /**
   Create a context instance.

   创建 context 实例
   */
  public init() {}

  /**
   Create a context instance that is initially synced with
   the provided `controller` and that sets `screenSize` to
   the main screen size.

   创建一个 context 实例，初始时与提供的 `controller` 同步，并将 `screenSize` 设置为主屏幕尺寸。

   - Parameters:
     - controller: The controller with which the context should sync, if any.
                   Context 应与之同步的 controller（如果有）。
   */
  public convenience init(
    controller: KeyboardInputViewController?
  ) {
    self.init()
    guard let controller = controller else { return }
    self.hamsterConfig = controller.hamsterConfiguration
    sync(with: controller)
  }
}

// MARK: - Public iOS/tvOS Properties

public extension KeyboardContext {
  /**
   The current trait collection's color scheme.

   当前特征集合中的配色方案。
   */
  var colorScheme: UIUserInterfaceStyle {
    traitCollection.userInterfaceStyle
  }

  /**
   The current keyboard appearance, with `.light` fallback.

   当前键盘外观，使用 `.light` 后备。
   */
  var keyboardAppearance: UIKeyboardAppearance {
    textDocumentProxy.keyboardAppearance ?? .default
  }
}

// MARK: - Public Properties

public extension KeyboardContext {
  /**
   The standard auto-capitalization type that will be used
   by the keyboard.

   键盘将使用的标准自动大写类型。

   This is by default fetched from the text document proxy
   for iOS and tvOS and is `.none` for all other platforms.
   You can set ``autocapitalizationTypeOverride`` to set a
   custom value that overrides the default one.

   默认情况下，iOS 和 tvOS 会从 documentProxy 获取该值，所有其他平台则为 `.none`。
   你可以设置 ``autocapitalizationTypeOverride`` 来设置一个覆盖默认值的自定义值。
   */
  var autocapitalizationType: KeyboardAutocapitalizationType? {
    autocapitalizationTypeOverride ?? textDocumentProxy.autocapitalizationType?.keyboardType
  }

  /**
   Whether or not the context specifies that we should use
   a dark color scheme.
   */
  var hasDarkColorScheme: Bool {
    colorScheme == .dark
  }

  /**
   Try to map the current ``locale`` to a keyboard locale.

   尝试将当前的 ``locale`` 映射到键盘的 locale。
   */
//  var keyboardLocale: KeyboardLocale? {
//    KeyboardLocale.allCases.first { $0.localeIdentifier == locale.identifier }
//  }
}

// MARK: - Public Functions

public extension KeyboardContext {
  /**
   Whether or not the context has multiple locales.

   上下文是否有多个本地语言。
   */
  var hasMultipleLocales: Bool {
    locales.count > 1
  }

  /**
   Whether or not the context has a certain locale.

   上下文是否具有特定的语言。
   */
//  func hasKeyboardLocale(_ locale: KeyboardLocale) -> Bool {
//    self.locale.identifier == locale.localeIdentifier
//  }

  /**
   Whether or not the context has a certain keyboard type.

   是否有特定的键盘类型。
   */
  func hasKeyboardType(_ type: KeyboardType) -> Bool {
    keyboardType == type
  }

  /**
   Select the next locale in ``locales``, depending on the
   ``locale``. If ``locale`` is last in ``locales`` or not
   in the list, the first list locale is selected.

   根据 ``locale`` 选择 ``locales`` 中的下一个本地语言。如果 ``locale`` 是 ``locales`` 中的最后一个或不在列表中，则选择列表中的第一个 locale。
   */
  func selectNextLocale() {
    let fallback = locales.first ?? locale
    guard let currentIndex = locales.firstIndex(of: locale) else { return locale = fallback }
    let nextIndex = currentIndex.advanced(by: 1)
    guard locales.count > nextIndex else { return locale = fallback }
    locale = locales[nextIndex]
  }

  /**
   Set ``keyboardType`` to the provided `type`.

   设置键盘类型
   */
  func setKeyboardType(_ type: KeyboardType) {
    keyboardType = type
  }

  /**
   Set ``locale`` to the provided `locale`.

   设置当前语言
   */
  func setLocale(_ locale: Locale) {
    self.locale = locale
  }

  /**
   Set ``locale`` to the provided keyboard `locale`.

   根据 KeyboardLocale 类型设置当前语言
   */
//  func setLocale(_ locale: KeyboardLocale) {
//    self.locale = locale.locale
//  }

  /**
   Set ``locales`` to the provided `locales`.
   */
  func setLocales(_ locales: [Locale]) {
    self.locales = locales
  }

  /**
   Set ``locales`` to the provided keyboard `locales`.
   */
//  func setLocales(_ locales: [KeyboardLocale]) {
//    self.locales = locales.map { $0.locale }
//  }
}

// MARK: - iOS/tvOS syncing

extension KeyboardContext {
  /**
   Sync the context with the current state of the keyboard
   input view controller.

   将上下文与键盘输入视图控制器的当前状态同步。
   */
  func sync(with controller: KeyboardInputViewController) {
    DispatchQueue.main.async {
      self.syncAfterAsync(with: controller)
    }
  }

  /**
   Perform this after an async delay, to make sure that we
   have the latest information.

   将上下文与键盘输入视图控制器的当前状态同步。
   */
  func syncAfterAsync(with controller: KeyboardInputViewController) {
    if hasDictationKey != controller.hasDictationKey {
      hasDictationKey = controller.hasDictationKey
    }
    if hasFullAccess != controller.hasFullAccess {
      hasFullAccess = controller.hasFullAccess
    }
    if needsInputModeSwitchKey != controller.needsInputModeSwitchKey {
      needsInputModeSwitchKey = controller.needsInputModeSwitchKey
    }
    if primaryLanguage != controller.primaryLanguage {
      primaryLanguage = controller.primaryLanguage
    }
    if interfaceOrientation != controller.orientation {
      interfaceOrientation = controller.orientation
    }

    let newPrefersAutocomplete = keyboardType.prefersAutocomplete && (textDocumentProxy.keyboardType?.prefersAutocomplete ?? true)
    if prefersAutocomplete != newPrefersAutocomplete {
      prefersAutocomplete = newPrefersAutocomplete
    }

    if screenSize != controller.screenSize {
      screenSize = controller.screenSize
    }

    if mainTextDocumentProxy === controller.mainTextDocumentProxy {} else {
      mainTextDocumentProxy = controller.mainTextDocumentProxy
    }
    if textDocumentProxy === controller.textDocumentProxy {} else {
      textDocumentProxy = controller.textDocumentProxy
    }
    if textInputMode != controller.textInputMode {
      textInputMode = controller.textInputMode
    }
    if traitCollection != controller.traitCollection {
      traitCollection = controller.traitCollection
    }
  }

  func syncAfterLayout(with controller: KeyboardInputViewController) {
    syncIsFloating(with: controller)
    if controller.orientation == interfaceOrientation { return }
    sync(with: controller)
  }

  /**
   Perform a sync to check if the keyboard is floating.
   */
  func syncIsFloating(with controller: KeyboardInputViewController) {
    let isFloating = controller.view.frame.width < screenSize.width / 2
    if isKeyboardFloating == isFloating { return }
    isKeyboardFloating = isFloating
  }
}

// MARK: - Hamster Configuration

public extension KeyboardContext {
  var hamsterKeyboardColor: HamsterModel.KeyboardColor? {
    if let cacheHamsterKeyboardColor = cacheHamsterKeyboardColor {
      return cacheHamsterKeyboardColor
    }

    guard hamsterConfig?.Keyboard?.enableColorSchema ?? false else { return nil }
    guard let schemaName = hamsterConfig?.Keyboard?.useColorSchema else { return nil }
    guard let schema = hamsterConfig?.Keyboard?.colorSchemas?[schemaName] else { return nil }

    self.cacheHamsterKeyboardColor = HamsterModel.KeyboardColor(name: schemaName, colorSchema: schema)
    return cacheHamsterKeyboardColor
  }
}

private extension UIInputViewController {
  var orientation: InterfaceOrientation {
    view.window?.screen.interfaceOrientation ?? .portrait
  }

  var screenSize: CGSize {
    view.window?.screen.bounds.size ?? .zero
  }
}

public extension KeyboardContext {
  /// 是否开启工具栏
  var enableToolbar: Bool {
    hamsterConfig?.toolbar?.enableToolbar ?? true
  }

  /// 是否开启按键气泡
  var displayButtonBubbles: Bool {
    (hamsterConfig?.Keyboard?.displayButtonBubbles ?? false) && keyboardType.displayButtonBubbles
  }

  /// 数字九宫格符号列表
  var symbolsOfNumericNineGridKeyboard: [String] {
    hamsterConfig?.Keyboard?.symbolsOfGridOfNumericKeyboard ?? []
  }

  /// 中文九宫格符号
  var symbolsOfChineseNineGridKeyboard: [String] {
    hamsterConfig?.Keyboard?.symbolsOfChineseNineGridKeyboard ?? []
  }

  /// 工具栏高度
  var heightOfToolbar: CGFloat {
    CGFloat(hamsterConfig?.toolbar?.heightOfToolbar ?? 55)
  }

  /// 工具栏编码区高度
  var heightOfCodingArea: CGFloat {
    CGFloat(hamsterConfig?.toolbar?.heightOfCodingArea ?? 15)
  }

  /// 是否开启键盘配色
  var enableHamsterKeyboardColor: Bool {
    hamsterConfig?.Keyboard?.enableColorSchema ?? false
  }

  /// Hamster 键盘配色
  var keyboardColor: HamsterModel.KeyboardColor? {
    if hamsterConfig?.Keyboard?.enableColorSchema ?? false, let color = hamsterKeyboardColor {
      return color
    }
    return nil
  }

  /// 背景色
  var backgroundColor: UIColor {
    if let keyboardColor = hamsterKeyboardColor {
      return keyboardColor.backColor
    }
    return .clear
  }

  /// 编码区拼音颜色
  var phoneticTextColor: UIColor {
    if let keyboardColor = hamsterKeyboardColor {
      return keyboardColor.textColor
    }
    return .label
  }

  /// 候选字颜色
  var candidateTextColor: UIColor {
    if let keyboardColor = hamsterKeyboardColor {
      return keyboardColor.candidateTextColor
    }
    return .label
  }

  /// secondaryLabel 颜色，如果开启仓配色，则取候选文字颜色
  var secondaryLabelColor: UIColor {
    if let keyboardColor = hamsterKeyboardColor {
      return keyboardColor.candidateTextColor
    }
    return .secondaryLabel
  }

  /// 分类符号键盘状态
  var classifySymbolKeyboardLockState: Bool {
    get {
      UserDefaults.standard.bool(forKey: "com.ihsiao.apps.hamster.keyboard.classifySymbolKeyboard.lockState")
    }
    set {
      UserDefaults.standard.set(newValue, forKey: "com.ihsiao.apps.hamster.keyboard.classifySymbolKeyboard.lockState")
    }
  }
}
