-- LockOnThemeModule.lua
-- Theme definitions for Lock-On Camera v3.2
-- Returns theme table + color utility

local module = {}

module.THEMES = {
    Ember = {
        primary1 = Color3.fromRGB(255, 60, 30),
        primary2 = Color3.fromRGB(200, 40, 80),
        secondary = Color3.fromRGB(35, 25, 30),
        background = Color3.fromRGB(20, 15, 18),
        text = Color3.fromRGB(255, 245, 240),
        glow = Color3.fromRGB(255, 100, 50),
        animSpeed = 2,
    },
    Ocean = {
        primary1 = Color3.fromRGB(30, 144, 255),
        primary2 = Color3.fromRGB(0, 200, 200),
        secondary = Color3.fromRGB(20, 35, 50),
        background = Color3.fromRGB(12, 22, 35),
        text = Color3.fromRGB(220, 240, 255),
        glow = Color3.fromRGB(50, 180, 255),
        animSpeed = 3,
    },
    Void = {
        primary1 = Color3.fromRGB(150, 50, 255),
        primary2 = Color3.fromRGB(255, 50, 150),
        secondary = Color3.fromRGB(25, 20, 40),
        background = Color3.fromRGB(15, 12, 25),
        text = Color3.fromRGB(240, 230, 255),
        glow = Color3.fromRGB(180, 100, 255),
        animSpeed = 2.5,
    },
    Neon = {
        primary1 = Color3.fromRGB(0, 255, 150),
        primary2 = Color3.fromRGB(0, 200, 255),
        secondary = Color3.fromRGB(15, 25, 25),
        background = Color3.fromRGB(8, 15, 15),
        text = Color3.fromRGB(220, 255, 250),
        glow = Color3.fromRGB(0, 255, 200),
        animSpeed = 1.5,
    },
    Sunset = {
        primary1 = Color3.fromRGB(255, 100, 50),
        primary2 = Color3.fromRGB(255, 50, 150),
        secondary = Color3.fromRGB(45, 30, 40),
        background = Color3.fromRGB(30, 20, 28),
        text = Color3.fromRGB(255, 245, 240),
        glow = Color3.fromRGB(255, 130, 80),
        animSpeed = 3,
    },
    Frost = {
        primary1 = Color3.fromRGB(180, 220, 255),
        primary2 = Color3.fromRGB(150, 200, 255),
        secondary = Color3.fromRGB(40, 50, 65),
        background = Color3.fromRGB(25, 35, 50),
        text = Color3.fromRGB(240, 250, 255),
        glow = Color3.fromRGB(150, 200, 255),
        animSpeed = 4,
    },
    Toxic = {
        primary1 = Color3.fromRGB(150, 255, 0),
        primary2 = Color3.fromRGB(0, 255, 100),
        secondary = Color3.fromRGB(25, 35, 20),
        background = Color3.fromRGB(15, 22, 12),
        text = Color3.fromRGB(230, 255, 220),
        glow = Color3.fromRGB(120, 255, 50),
        animSpeed = 2,
    },
    Blood = {
        primary1 = Color3.fromRGB(180, 0, 0),
        primary2 = Color3.fromRGB(120, 0, 50),
        secondary = Color3.fromRGB(35, 15, 20),
        background = Color3.fromRGB(20, 10, 12),
        text = Color3.fromRGB(255, 220, 220),
        glow = Color3.fromRGB(200, 50, 50),
        animSpeed = 2.5,
    },
}

module.DEFAULT = "Ember"

function module.lerpColor(c1, c2, t)
    return Color3.new(
        c1.R + (c2.R - c1.R) * t,
        c1.G + (c2.G - c1.G) * t,
        c1.B + (c2.B - c1.B) * t
    )
end

return module
