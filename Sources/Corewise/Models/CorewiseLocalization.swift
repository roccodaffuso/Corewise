import Foundation

func corewiseText(_ key: String, comment: String = "") -> String {
  NSLocalizedString(key, bundle: .main, comment: comment)
}

func corewiseFormat(_ key: String, _ arguments: CVarArg...) -> String {
  String(
    format: NSLocalizedString(key, bundle: .main, comment: "Corewise formatted user-facing copy"),
    locale: .current,
    arguments: arguments
  )
}
