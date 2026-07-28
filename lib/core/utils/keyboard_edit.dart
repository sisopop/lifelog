// 소프트 자판(키보드) 때문에 글이 가려지는 "편집 중" 상태 판정.
//
// 안드로이드/iOS는 자판이 뜨면 viewInsets.bottom > 0 이 되지만, **Flutter 웹은
// 소프트 자판 높이를 viewInsets로 보고하지 않는다(항상 0)**. 대신 모바일 브라우저는
// 자판이 뜰 때 창(뷰포트) 자체를 줄이므로, 웹에서는 "포커스만" 으로 편집 중을
// 판정하고 남은 높이는 뷰포트 크기로 계산하면 된다.
//
// 이 판정을 순수 함수로 빼서 세 곳(글쓰기 본문 편집기, 꾸미기 텍스트박스 편집기,
// 꾸미기 캔버스 밀기)이 같은 규칙을 쓰게 한다.

/// 자판이 올라온 상태로 편집 중인지 여부.
///
/// [hasFocus]는 편집기 포커스, [keyboardHeight]는 `viewInsets.bottom`,
/// [isWeb]은 `kIsWeb`. 웹에서는 [keyboardHeight]가 항상 0이라 포커스만 본다.
bool isKeyboardEditing({
  required bool hasFocus,
  required double keyboardHeight,
  bool isWeb = false,
}) =>
    hasFocus && (isWeb || keyboardHeight > 0);
