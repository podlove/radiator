import { getNodeByEvent } from "../../node";

export function focusin(event: FocusEvent) {
  const { uuid } = getNodeByEvent(event);

  this.pushEventTo(this.el, "set_focus", uuid);
}

export function focusout(event: FocusEvent) {
  const { uuid } = getNodeByEvent(event);

  this.pushEventTo(this.el, "remove_focus", uuid);
}
