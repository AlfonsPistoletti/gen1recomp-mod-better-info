return function(ctx)
    if not ctx.exists("townmap/up_arrow.png") then
        return
    end

    local img = ctx.readImage("townmap/up_arrow.png")
    ctx.writeImage(img, "townmap/up_arrow.png")

    if not ctx.exists("townmap/nest.png") then
        return
    end

    local img = ctx.readImage("townmap/nest.png")
    ctx.writeImage(img, "townmap/nest.png")
end