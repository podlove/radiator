import { focusin, focusout, input, keydown } from "./event_listener"
import { handleList, handleInsert, handleUpdate, handleDelete } from "./event_handler"

export const Hooks = {
  outline: {
    mounted() {
      const container: HTMLOListElement = this.el

      container.addEventListener("focusin", focusin.bind(this))
      container.addEventListener("focusout", focusout.bind(this))
      container.addEventListener("input", input.bind(this))

      container.addEventListener("keydown", keydown.bind(this))
      // container.addEventListener("keyup", keyup.bind(this))

      this.handleEvent("list", handleList.bind(this))
      this.handleEvent("insert", handleInsert.bind(this))
      this.handleEvent("update", handleUpdate.bind(this))
      this.handleEvent("delete", handleDelete.bind(this))
    }
  }
}
