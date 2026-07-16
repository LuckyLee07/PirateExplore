#!/usr/bin/env python3
"""Source contract regression for the manual-retain-counted iOS render view."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
HEADER = ROOT / "src/engine/cocos2d-x/cocos/2d/platform/ios/CCEAGLView.h"
SOURCE = ROOT / "src/engine/cocos2d-x/cocos/2d/platform/ios/CCEAGLView.mm"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def method_body(source: str, signature: str, next_signature: str) -> str:
    start = source.find(signature)
    require(start >= 0, f"missing method: {signature}")
    end = source.find(next_signature, start + len(signature))
    require(end > start, f"missing method boundary after: {signature}")
    return source[start:end]


def main() -> None:
    header = HEADER.read_text(encoding="utf-8")
    source = SOURCE.read_text(encoding="utf-8")

    require("NSDictionary *          markedTextStyle_;" in header,
            "marked-text style must have an explicit MRC ivar")
    require("@synthesize markedTextStyle = markedTextStyle_;" in source,
            "property must bind to the owned ivar")

    dealloc = method_body(source, "- (void) dealloc", "- (void) layoutSubviews")
    for marker in (
        "removeObserver:self",
        "[markedText_ release]",
        "[markedTextStyle_ release]",
        "self.keyboardShowNotification = nil",
        "[super dealloc]",
    ):
        require(marker in dealloc, f"dealloc ownership cleanup is missing: {marker}")
    require(dealloc.index("[markedTextStyle_ release]") < dealloc.index("[super dealloc]"),
            "owned style must be released before super dealloc")

    style_setter = method_body(
        source,
        "- (void)setMarkedTextStyle:(NSDictionary *)markedTextStyle;",
        "- (NSDictionary *)markedTextStyle;",
    )
    require("[markedTextStyle_ release]" in style_setter,
            "style replacement must release the previous copy")
    require("markedTextStyle_ = [markedTextStyle copy]" in style_setter,
            "style replacement must honor the copy property")

    selection_rects = method_body(
        source,
        "- (NSArray *)selectionRectsForRange:(UITextRange *)range",
        "#pragma mark - UIKeyboard notification",
    )
    require("return [NSArray array];" in selection_rects,
            "UITextInput selection rect contract must return a non-null array")
    require("return nil;" not in selection_rects,
            "UITextInput selection rect contract regressed to nil")

    print("CCEAGLView contract OK: MRC cleanup, copied style and non-null selection rects")


if __name__ == "__main__":
    main()
