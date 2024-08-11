export type UUID = `${string}-${string}-${string}-${string}-${string}`;

export interface Node {
  uuid: UUID;
  content?: string;
  creator_id?: number;
  parent_id?: UUID;
  prev_id?: UUID;
  collapsed?: boolean;
  dirty: boolean;
}
