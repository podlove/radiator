export type UUID = `${string}-${string}-${string}-${string}-${string}`;

export interface Node {
  event_id?: UUID;
  uuid?: UUID;
  content: string;
  creator_id?: number;
  parent_id?: UUID;
  prev_id?: UUID;
  dirty?: boolean;
}
