import {
  useCallback,
  useEffect,
  useImperativeHandle,
  useMemo,
  useRef,
} from 'react';
import type React from 'react';
import EnrichedMarkdownInputNativeComponent, {
  Commands,
  type NativeProps,
  type OnChangeTextEvent,
  type OnChangeMarkdownEvent,
  type OnChangeSelectionEvent,
  type OnChangeStateEvent,
  type OnRequestMarkdownResultEvent,
  type OnRequestCaretRectResultEvent,
  type OnCaretRectChangeEvent,
  type OnContextMenuItemPressEvent,
  type OnLinkDetected,
} from './EnrichedMarkdownInputNativeComponent';
export type { OnLinkDetected } from './EnrichedMarkdownInputNativeComponent';
import type {
  HostInstance,
  NativeSyntheticEvent,
  ViewStyle,
  TextStyle,
  ColorValue,
} from 'react-native';
import { normalizeMarkdownInputStyle } from './normalizeMarkdownInputStyle';
import { toNativeRegexConfig } from './utils/regexParser';
import type { RefObject } from 'react';

type NativeRef = HostInstance;

export interface MarkdownInputStyle {
  strong?: {
    color?: string;
  };
  em?: {
    color?: string;
  };
  link?: {
    color?: string;
    underline?: boolean;
  };
  spoiler?: {
    color?: string;
    backgroundColor?: string;
  };
}

export interface StyleState {
  bold: { isActive: boolean };
  italic: { isActive: boolean };
  underline: { isActive: boolean };
  strikethrough: { isActive: boolean };
  spoiler: { isActive: boolean };
  link: { isActive: boolean };
}

export interface ContextMenuItem {
  text: string;
  onPress: (event: {
    text: string;
    selection: { start: number; end: number };
    styleState: StyleState;
  }) => void;
  icon?: string;
  visible?: boolean;
}

export interface CaretRect {
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface EnrichedMarkdownInputInstance {
  focus: () => void;
  blur: () => void;
  measure: HostInstance['measure'];
  measureInWindow: HostInstance['measureInWindow'];
  measureLayout: HostInstance['measureLayout'];
  setValue: (markdown: string) => void;
  setSelection: (start: number, end: number) => void;
  toggleBold: () => void;
  toggleItalic: () => void;
  toggleUnderline: () => void;
  toggleStrikethrough: () => void;
  toggleSpoiler: () => void;
  setLink: (url: string) => void;
  insertLink: (text: string, url: string) => void;
  removeLink: () => void;
  getMarkdown: () => Promise<string>;
  getCaretRect: () => Promise<CaretRect>;
}

export interface EnrichedMarkdownInputProps {
  ref?: RefObject<EnrichedMarkdownInputInstance | null>;
  defaultValue?: string;
  placeholder?: string;
  placeholderTextColor?: ColorValue;
  editable?: boolean;
  autoFocus?: boolean;
  scrollEnabled?: boolean;
  autoCapitalize?: string;
  multiline?: boolean;
  cursorColor?: ColorValue;
  selectionColor?: ColorValue;
  markdownStyle?: MarkdownInputStyle;
  style?: ViewStyle | TextStyle;
  onChangeText?: (text: string) => void;
  onChangeMarkdown?: (markdown: string) => void;
  onChangeSelection?: (selection: { start: number; end: number }) => void;
  onChangeState?: (state: StyleState) => void;
  onCaretRectChange?: (rect: CaretRect) => void;
  onLinkDetected?: (event: OnLinkDetected) => void;
  onFocus?: () => void;
  onBlur?: () => void;
  contextMenuItems?: ContextMenuItem[];
  linkRegex?: RegExp | null;
}

type PendingRequest<T> = {
  resolve: (value: T) => void;
  reject: (error: Error) => void;
};

function getNativeRef(ref: React.RefObject<NativeRef | null>): NativeRef {
  if (ref.current == null) {
    throw new Error(
      'EnrichedMarkdownInput: native ref is not attached. Ensure the component is mounted.'
    );
  }
  return ref.current;
}

export const EnrichedMarkdownInput = ({
  ref,
  markdownStyle,
  style,
  defaultValue,
  placeholder,
  placeholderTextColor,
  editable = true,
  autoFocus = false,
  scrollEnabled = true,
  autoCapitalize = 'sentences',
  multiline = true,
  cursorColor,
  selectionColor,
  onChangeText,
  onChangeMarkdown,
  onChangeSelection,
  onChangeState,
  onCaretRectChange,
  onLinkDetected,
  onFocus,
  onBlur,
  contextMenuItems,
  linkRegex: _linkRegex,
}: EnrichedMarkdownInputProps) => {
  const nativeRef = useRef<NativeRef | null>(null);

  const nextRequestId = useRef(1);
  const pendingRequests = useRef(new Map<number, PendingRequest<string>>());
  const pendingCaretRectRequests = useRef(
    new Map<number, PendingRequest<CaretRect>>()
  );

  const contextMenuCallbacksRef = useRef<
    Map<string, ContextMenuItem['onPress']>
  >(new Map());

  useEffect(() => {
    const callbacksMap = new Map<string, ContextMenuItem['onPress']>();
    if (contextMenuItems) {
      for (const item of contextMenuItems) {
        callbacksMap.set(item.text, item.onPress);
      }
    }
    contextMenuCallbacksRef.current = callbacksMap;
  }, [contextMenuItems]);

  const nativeContextMenuItems = useMemo(
    () =>
      contextMenuItems
        ?.filter((item) => item.visible !== false)
        .map((item) => ({ text: item.text, icon: item.icon })),
    [contextMenuItems]
  );

  useEffect(() => {
    const pending = pendingRequests.current;
    const pendingCaretRect = pendingCaretRectRequests.current;
    return () => {
      const err = new Error('Component unmounted');
      pending.forEach(({ reject }) => reject(err));
      pending.clear();
      pendingCaretRect.forEach(({ reject }) => reject(err));
      pendingCaretRect.clear();
    };
  }, []);

  const normalizedStyle = normalizeMarkdownInputStyle(markdownStyle);

  const linkRegex = useMemo(
    () => toNativeRegexConfig(_linkRegex),
    [_linkRegex]
  );

  const handleLinkDetected = useCallback(
    (e: NativeSyntheticEvent<OnLinkDetected>) => {
      const { text, url, start, end } = e.nativeEvent;
      onLinkDetected?.({ text, url, start, end });
    },
    [onLinkDetected]
  );

  const handleChangeText = useCallback(
    (e: NativeSyntheticEvent<OnChangeTextEvent>) => {
      onChangeText?.(e.nativeEvent.value);
    },
    [onChangeText]
  );

  const handleChangeMarkdown = useCallback(
    (e: NativeSyntheticEvent<OnChangeMarkdownEvent>) => {
      onChangeMarkdown?.(e.nativeEvent.value);
    },
    [onChangeMarkdown]
  );

  const handleChangeSelection = useCallback(
    (e: NativeSyntheticEvent<OnChangeSelectionEvent>) => {
      const { start, end } = e.nativeEvent;
      onChangeSelection?.({ start, end });
    },
    [onChangeSelection]
  );

  const handleChangeState = useCallback(
    (e: NativeSyntheticEvent<OnChangeStateEvent>) => {
      const { bold, italic, underline, strikethrough, spoiler, link } =
        e.nativeEvent;
      onChangeState?.({
        bold,
        italic,
        underline,
        strikethrough,
        spoiler,
        link,
      });
    },
    [onChangeState]
  );

  const handleCaretRectChange = useCallback(
    (e: NativeSyntheticEvent<OnCaretRectChangeEvent>) => {
      const { x, y, width, height } = e.nativeEvent;
      onCaretRectChange?.({ x, y, width, height });
    },
    [onCaretRectChange]
  );

  const handleFocus = useCallback(() => {
    onFocus?.();
  }, [onFocus]);

  const handleBlur = useCallback(() => {
    onBlur?.();
  }, [onBlur]);

  const handleRequestMarkdownResult = useCallback(
    (e: NativeSyntheticEvent<OnRequestMarkdownResultEvent>) => {
      const { requestId, markdown } = e.nativeEvent;
      const pending = pendingRequests.current.get(requestId);
      if (!pending) return;

      pending.resolve(markdown);
      pendingRequests.current.delete(requestId);
    },
    []
  );

  const handleRequestCaretRectResult = useCallback(
    (e: NativeSyntheticEvent<OnRequestCaretRectResultEvent>) => {
      const { requestId, x, y, width, height } = e.nativeEvent;
      const pending = pendingCaretRectRequests.current.get(requestId);
      if (!pending) return;

      pending.resolve({ x, y, width, height });
      pendingCaretRectRequests.current.delete(requestId);
    },
    []
  );

  const handleContextMenuItemPress = useCallback(
    (e: NativeSyntheticEvent<OnContextMenuItemPressEvent>) => {
      const {
        itemText,
        selectedText,
        selectionStart,
        selectionEnd,
        styleState,
      } = e.nativeEvent;
      const callback = contextMenuCallbacksRef.current.get(itemText);
      callback?.({
        text: selectedText,
        selection: { start: selectionStart, end: selectionEnd },
        styleState,
      });
    },
    []
  );

  useImperativeHandle(ref, () => {
    const node = getNativeRef(nativeRef);
    // Codegen's ViewRef resolves to `never` with RN 0.84's function-based
    // HostComponent type — the cast is safe at runtime.
    const commandRef = node as Parameters<(typeof Commands)['focus']>[0];
    return {
      measure: (callback) => node.measure(callback),
      measureInWindow: (callback) => node.measureInWindow(callback),
      measureLayout: (relativeToNativeNode, onSuccess, onFail) =>
        node.measureLayout(relativeToNativeNode, onSuccess, onFail),
      focus: () => Commands.focus(commandRef),
      blur: () => Commands.blur(commandRef),
      setValue: (markdown) => Commands.setValue(commandRef, markdown),
      setSelection: (start, end) =>
        Commands.setSelection(commandRef, start, end),
      toggleBold: () => Commands.toggleBold(commandRef),
      toggleItalic: () => Commands.toggleItalic(commandRef),
      toggleUnderline: () => Commands.toggleUnderline(commandRef),
      toggleStrikethrough: () => Commands.toggleStrikethrough(commandRef),
      toggleSpoiler: () => Commands.toggleSpoiler(commandRef),
      setLink: (url) => Commands.setLink(commandRef, url),
      insertLink: (text, url) => Commands.insertLink(commandRef, text, url),
      removeLink: () => Commands.removeLink(commandRef),
      getMarkdown: () =>
        new Promise<string>((resolve, reject) => {
          const requestId = nextRequestId.current++;
          pendingRequests.current.set(requestId, { resolve, reject });
          Commands.requestMarkdown(commandRef, requestId);
        }),
      getCaretRect: () =>
        new Promise<CaretRect>((resolve, reject) => {
          const requestId = nextRequestId.current++;
          pendingCaretRectRequests.current.set(requestId, {
            resolve,
            reject,
          });
          Commands.requestCaretRect(commandRef, requestId);
        }),
    };
  });

  return (
    <EnrichedMarkdownInputNativeComponent
      ref={nativeRef}
      style={style}
      markdownStyle={normalizedStyle}
      defaultValue={defaultValue}
      placeholder={placeholder}
      placeholderTextColor={placeholderTextColor}
      editable={editable}
      autoFocus={autoFocus}
      scrollEnabled={scrollEnabled}
      autoCapitalize={autoCapitalize}
      multiline={multiline}
      cursorColor={cursorColor}
      selectionColor={selectionColor}
      isOnChangeMarkdownSet={onChangeMarkdown !== undefined}
      onChangeText={handleChangeText as NativeProps['onChangeText']}
      onChangeMarkdown={handleChangeMarkdown as NativeProps['onChangeMarkdown']}
      onChangeSelection={
        handleChangeSelection as NativeProps['onChangeSelection']
      }
      onChangeState={handleChangeState as NativeProps['onChangeState']}
      onLinkDetected={handleLinkDetected as NativeProps['onLinkDetected']}
      onInputFocus={handleFocus as NativeProps['onInputFocus']}
      onInputBlur={handleBlur as NativeProps['onInputBlur']}
      onRequestMarkdownResult={
        handleRequestMarkdownResult as NativeProps['onRequestMarkdownResult']
      }
      onRequestCaretRectResult={
        handleRequestCaretRectResult as NativeProps['onRequestCaretRectResult']
      }
      onCaretRectChange={
        handleCaretRectChange as NativeProps['onCaretRectChange']
      }
      contextMenuItems={nativeContextMenuItems}
      onContextMenuItemPress={
        handleContextMenuItemPress as NativeProps['onContextMenuItemPress']
      }
      linkRegex={linkRegex}
    />
  );
};

export default EnrichedMarkdownInput;
