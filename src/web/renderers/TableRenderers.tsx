import type { RendererProps, RendererMap } from '../types';
import {
  tableCSS,
  tableWrapperCSS,
  tableBodyRowCSS,
  tableHeaderCellCSS,
  tableCellCSS,
} from '../cssMap';

function TableRenderer({ node, style, renderChildren }: RendererProps) {
  return (
    <div style={tableWrapperCSS(style)}>
      <table style={tableCSS(style)}>{renderChildren(node)}</table>
    </div>
  );
}

function TableHeadRenderer({ node, renderChildren }: RendererProps) {
  return <thead>{renderChildren(node)}</thead>;
}

function TableBodyRenderer({ node, style, renderChildren }: RendererProps) {
  return (
    <tbody>
      {node.children?.map((rowNode, rowIndex) => (
        <tr key={rowIndex} style={tableBodyRowCSS(style, rowIndex)}>
          {renderChildren(rowNode)}
        </tr>
      ))}
    </tbody>
  );
}

function TableRowRenderer({ node, renderChildren }: RendererProps) {
  return <tr>{renderChildren(node)}</tr>;
}

function TableHeaderCellRenderer({
  node,
  style,
  renderChildren,
}: RendererProps) {
  return (
    <th style={tableHeaderCellCSS(style, node.attributes?.align)}>
      {renderChildren(node)}
    </th>
  );
}

function TableCellRenderer({ node, style, renderChildren }: RendererProps) {
  return (
    <td style={tableCellCSS(style, node.attributes?.align)}>
      {renderChildren(node)}
    </td>
  );
}

export const tableRenderers: RendererMap = {
  Table: TableRenderer,
  TableHead: TableHeadRenderer,
  TableBody: TableBodyRenderer,
  TableRow: TableRowRenderer,
  TableHeaderCell: TableHeaderCellRenderer,
  TableCell: TableCellRenderer,
};
