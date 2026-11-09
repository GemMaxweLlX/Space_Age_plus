-- Дневник инженера — runtime. Пока только окно; записи (журналы, комментарии,
-- инопланетные данные, выбор предыстории) добавляются следующими шагами.

local diary = {}

local GUI_NAME = "sap_diary_frame"

function diary.toggle(event)
  local player = game.get_player(event.player_index)
  if not player then return end
  local frame = player.gui.screen[GUI_NAME]
  if frame then
    frame.destroy()
    return
  end
  frame = player.gui.screen.add({
    type = "frame", name = GUI_NAME, direction = "vertical", caption = { "sap-diary.title" },
  })
  frame.auto_center = true
  frame.add({ type = "label", caption = { "sap-diary.empty" } })
end

return diary
