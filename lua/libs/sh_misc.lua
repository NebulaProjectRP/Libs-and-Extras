
function p(x)
    return x and player.GetByID(x) or (CLIENT and LocalPlayer() or player.GetByID(1))
end