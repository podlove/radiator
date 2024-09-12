export type UUID = `${string}-${string}-${string}-${string}-${string}`;

export type UserAction = {
  uuid: UUID;
  user_name: string;
};

export type CollapseParams = {
  detail: UserAction;
};

export interface NodeData {
  uuid: UUID;
  content?: string;
  creator_id?: number;
  parent_id?: UUID;
  prev_id?: UUID;
  collapsed?: boolean;
}
