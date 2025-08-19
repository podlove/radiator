export interface DataNode {
  uuid: UUID;
  parent_id?: UUID;
  prev_id?: UUID;
  content: string;
  collapsed: boolean;
  // selected: boolean;
  // creator_id?: number;
}

export type DomContainer = HTMLDivElement;

export type DomNode = HTMLDivElement;

export type UUID = `${string}-${string}-${string}-${string}-${string}`;
