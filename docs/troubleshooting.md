# Troubleshooting

## Highlight Not Visible on Anomaly Replacement

### Symptom
Debug prints show `HL SET` and `HL ENABLED` for a replacement object, but the yellow outline does not appear visually. The same Highlight system works on other objects.

### Root Cause
The replacement part has **Transparency = 1** (completely invisible). The Highlight wraps the part with a yellow fill + outline, but if the part itself has no visible surface, the highlight has nothing to render on and appears invisible too.

### Fix
In `AnomalySwapper.luau`, after moving a replacement to its show position and renaming it, iterate all its `BasePart` descendants and set `Transparency = 0`.

```lua
local parts = {}
if replacement:IsA("BasePart") then
    parts = { replacement }
elseif replacement:IsA("Model") then
    for _, v in replacement:GetDescendants() do
        if v:IsA("BasePart") then table.insert(parts, v) end
    end
end
for _, p in ipairs(parts) do
    p.Transparency = 0
end
```

### Prevention
When creating replacement objects in the Floor template (`ServerStorage.Templates.Floor.Anomaly`), ensure all BasePart children have `Transparency = 0`. If a replacement is designed to be invisible in the template (e.g., for a hide-state), the swap code must reset visibility explicitly.
