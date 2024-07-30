import { getNodeByEvent } from "../../node";

export function focusin(event: FocusEvent) {
  const { uuid } = getNodeByEvent(event);

  this.pushEvent("set_focus", uuid);
}

export function focusout(event: FocusEvent) {
  const { uuid } = getNodeByEvent(event);

  this.pushEvent("remove_focus", uuid);
}
