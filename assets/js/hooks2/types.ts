export interface DataNode {
  uuid: UUID;
  // content?: string;
  // creator_id?: number;
  parent_id?: UUID;
  prev_id?: UUID;
  collapsed?: boolean;
  // selected?: boolean;
}

export type DomContainer = HTMLDivElement;

export type DomNode = HTMLDivElement;

export type UUID = `${string}-${string}-${string}-${string}-${string}`;
