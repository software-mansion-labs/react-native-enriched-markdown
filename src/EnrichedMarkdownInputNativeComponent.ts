import {
  codegenNativeComponent,
  codegenNativeCommands,
  type ViewProps,
  type ColorValue,
  type HostComponent,
} from 'react-native';
import type {
  DirectEventHandler,
  Float,
  Int32,
} from 'react-native/Libraries/Types/CodegenTypes';
import type React from 'react';

interface MarkdownInputStyleInternal {
  strong: {
    color?: ColorValue;
  };
  em: {
    color?: ColorValue;
  };
  link: {
    color: ColorValue;
    underline: boolean;
  };
  syntax: {
    color: ColorValue;
  };
}

interface TargetedEvent {
  target: Int32;
}

export interface OnChangeTextEvent {
  value: string;
}

export interface OnChangeMarkdownEvent {
  value: string;
}

export interface OnChangeSelectionEvent {
  start: Int32;
  end: Int32;
}

export interface OnChangeStateEvent {
  bold: { isActive: boolean };
  italic: { isActive: boolean };
  underline: { isActive: boolean };
  strikethrough: { isActive: boolean };
  link: { isActive: boolean };
}

export interface OnRequestMarkdownResultEvent {
  requestId: Int32;
  markdown: string;
}

export interface NativeProps extends ViewProps {
  /**
   * Initial markdown content.
   */
  defaultValue?: string;
  /**
   * Placeholder text shown when the input is empty.
   */
  placeholder?: string;
  /**
   * Color of the placeholder text.
   */
  placeholderTextColor?: ColorValue;
  /**
   * Whether the input is editable.
   * @default true
   */
  editable?: boolean;
  /**
   * Whether the input should auto-focus on mount.
   * @default false
   */
  autoFocus?: boolean;
  /**
   * Whether the input is scrollable.
   * @default true
   */
  scrollEnabled?: boolean;
  /**
   * Auto-capitalization behavior.
   */
  autoCapitalize?: string;
  /**
   * Whether the input supports multiple lines.
   * @default true
   */
  multiline?: boolean;
  /**
   * Color of the cursor.
   */
  cursorColor?: ColorValue;
  /**
   * Color of the text selection highlight.
   */
  selectionColor?: ColorValue;
  /**
   * Inline format style overrides (link color, syntax color).
   * Always provided with complete defaults via normalizeMarkdownInputStyle.
   */
  markdownStyle: MarkdownInputStyleInternal;

  // These should not be passed as regular props.
  color?: ColorValue;
  fontSize?: Float;
  lineHeight?: Float;
  fontFamily?: string;
  fontWeight?: string;

  /**
   * Whether onChangeMarkdown handler is set. When true, the native side
   * serializes formatting ranges to Markdown on every change.
   */
  isOnChangeMarkdownSet?: boolean;

  // Events
  onChangeText?: DirectEventHandler<OnChangeTextEvent>;
  onChangeMarkdown?: DirectEventHandler<OnChangeMarkdownEvent>;
  onChangeSelection?: DirectEventHandler<OnChangeSelectionEvent>;
  onChangeState?: DirectEventHandler<OnChangeStateEvent>;
  onInputFocus?: DirectEventHandler<TargetedEvent>;
  onInputBlur?: DirectEventHandler<TargetedEvent>;
  onRequestMarkdownResult?: DirectEventHandler<OnRequestMarkdownResultEvent>;
}

type ComponentType = HostComponent<NativeProps>;

interface NativeCommands {
  focus: (viewRef: React.ElementRef<ComponentType>) => void;
  blur: (viewRef: React.ElementRef<ComponentType>) => void;
  setValue: (
    viewRef: React.ElementRef<ComponentType>,
    markdown: string
  ) => void;
  setSelection: (
    viewRef: React.ElementRef<ComponentType>,
    start: Int32,
    end: Int32
  ) => void;
  toggleBold: (viewRef: React.ElementRef<ComponentType>) => void;
  toggleItalic: (viewRef: React.ElementRef<ComponentType>) => void;
  toggleUnderline: (viewRef: React.ElementRef<ComponentType>) => void;
  toggleStrikethrough: (viewRef: React.ElementRef<ComponentType>) => void;
  setLink: (viewRef: React.ElementRef<ComponentType>, url: string) => void;
  removeLink: (viewRef: React.ElementRef<ComponentType>) => void;
  requestMarkdown: (
    viewRef: React.ElementRef<ComponentType>,
    requestId: Int32
  ) => void;
}

export const Commands: NativeCommands = codegenNativeCommands<NativeCommands>({
  supportedCommands: [
    'focus',
    'blur',
    'setValue',
    'setSelection',
    'toggleBold',
    'toggleItalic',
    'toggleUnderline',
    'toggleStrikethrough',
    'setLink',
    'removeLink',
    'requestMarkdown',
  ],
});

export default codegenNativeComponent<NativeProps>('EnrichedMarkdownInput', {
  interfaceOnly: true,
}) as HostComponent<NativeProps>;
