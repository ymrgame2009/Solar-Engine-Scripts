-- ╔══════════════════════════════════════════════════════╗
-- ║   V-Slice Hold Cover — Auto RGB / Multi-Color        ║
-- ║   Psych Engine 0.6.3  [FIXED v5]                     ║
-- ║   Solar Engine 0.6.X — Universe Engine 0.5.5	      ║
-- ║   By Mr YMR (@ymrgame2009)				              ║
-- ╚══════════════════════════════════════════════════════╝

local colorNames   = {'Purple', 'Blue', 'Green', 'Red'}
local playerCovers = {'coverP0', 'coverP1', 'coverP2', 'coverP3'}
local enemyCovers  = {'coverE0', 'coverE1', 'coverE2', 'coverE3'}

local rgbApplied = {
    player = {false, false, false, false},
    enemy  = {false, false, false, false}
}

local pActive = {false, false, false, false}
local eActive = {false, false, false, false}

-- يُفعَّل فقط من goodNoteHit/opponentNoteHit لما isSustainNote=true
local pHasSustain = {false, false, false, false}
local eHasSustain = {false, false, false, false}

local isPixelStage = false
local isBotPlay    = false
local useRGB       = false

-- ===================== SETUP =====================

function onCreatePost()
    isPixelStage = getPropertyFromClass('states.PlayState', 'isPixelStage')
    isBotPlay    = getPropertyFromClass('states.PlayState', 'cpuControlled')

    useRGB = getPropertyFromClass('backend.ClientPrefs', 'data.noteRGB')
    if useRGB == nil then useRGB = getPropertyFromClass('ClientPrefs', 'data.noteRGB') end
    if useRGB == nil then useRGB = getPropertyFromClass('backend.ClientPrefs', 'noteRGB') end
    if useRGB == nil then useRGB = true end

    for i = 0, 3 do
        setupCover(playerCovers[i+1], colorNames[i+1])
        setupCover(enemyCovers[i+1],  colorNames[i+1])
    end
end

function setupCover(tag, color)
    local image
    if useRGB then
        image = isPixelStage and 'holdCoverPixelRGB' or 'holdCoverRGB'
        makeAnimatedLuaSprite(tag, image, 0, 0)
        if isPixelStage then
            addAnimationByPrefix(tag, 'hold', 'holdCoverRGB',    24, true)
            addAnimationByPrefix(tag, 'end',  'holdCoverEndRGB', 24, false)
        else
            addAnimationByPrefix(tag, 'start', 'holdCoverStartRGB', 24, false)
            addAnimationByPrefix(tag, 'hold',  'holdCoverRGB',      24, true)
            addAnimationByPrefix(tag, 'end',   'holdCoverEndRGB',   24, false)
        end
    else
        image = 'holdCover' .. color
        makeAnimatedLuaSprite(tag, image, 0, 0)
        addAnimationByPrefix(tag, 'start', 'holdCoverStart' .. color, 24, false)
        addAnimationByPrefix(tag, 'hold',  'holdCover'      .. color, 24, true)
        addAnimationByPrefix(tag, 'end',   'holdCoverEnd'   .. color, 24, false)
    end

    setProperty(tag .. '.antialiasing', not isPixelStage)
    scaleObject(tag, 1, 1)
    setObjectCamera(tag, 'camHUD')
    setProperty(tag .. '.alpha', 0.0001)
    setProperty(tag .. '.visible', true)
    addLuaSprite(tag, true)
end

-- ===================== HELPERS =====================

function showCover(tag, dir, isPlayer)
    if isPlayer then
        pActive[dir+1]           = true
        rgbApplied.player[dir+1] = false
    else
        eActive[dir+1]           = true
        rgbApplied.enemy[dir+1]  = false
    end
    setProperty(tag..'.visible', true)
    setProperty(tag..'.alpha', 1)
    setProperty(tag..'.antialiasing', not isPixelStage)
    if getProperty(tag..'.animation.curAnim.name') ~= 'hold' then
        playAnim(tag, 'hold', true)
    end
end

function hideCover(tag, dir, isPlayer)
    if isPlayer then
        if not pActive[dir+1] then return end
        pActive[dir+1]           = false
        rgbApplied.player[dir+1] = false
        if getProperty(tag..'.animation.curAnim.name') == 'hold' then
            playAnim(tag, 'end', true)
            runTimer('fadeP'..dir, 0.333)
        else
            setProperty(tag..'.alpha', 0.0001)
        end
    else
        if not eActive[dir+1] then return end
        eActive[dir+1]          = false
        rgbApplied.enemy[dir+1] = false
        setProperty(tag..'.alpha', 0.0001)
    end
end

-- ===================== NOTE HIT =====================

function goodNoteHit(id, direction, noteType, isSustainNote)
    if direction == nil or direction < 0 or direction > 3 then return end
    if isSustainNote then
        pHasSustain[direction + 1] = true
    end
end

function opponentNoteHit(id, direction, noteType, isSustainNote)
    if direction == nil or direction < 0 or direction > 3 then return end
    if isSustainNote then
        eHasSustain[direction + 1] = true
    end
end

-- ===================== UPDATE =====================

function onUpdatePost(elapsed)
    for i = 0, 3 do
        local pTag   = playerCovers[i+1]
        local eTag   = enemyCovers[i+1]
        local pStrum = 'playerStrums.members['   .. i .. ']'
        local eStrum = 'opponentStrums.members[' .. i .. ']'

        updatePos(pTag, pStrum)
        updatePos(eTag, eStrum)

        -- RGB
        if useRGB then
            if getProperty(pTag..'.alpha') > 0.5 and not rgbApplied.player[i+1] then
                applyRGB(pTag, i, true)
                rgbApplied.player[i+1] = true
            end
            if getProperty(eTag..'.alpha') > 0.5 and not rgbApplied.enemy[i+1] then
                applyRGB(eTag, i, false)
                rgbApplied.enemy[i+1] = true
            end
        end

        local pAnim     = getProperty(pStrum..'.animation.curAnim.name')
        local pFinished = getProperty(pStrum..'.animation.finished')
        local eAnim     = getProperty(eStrum..'.animation.curAnim.name')
        local eFinished = getProperty(eStrum..'.animation.finished')

        -- ===== اللاعب =====
        if pHasSustain[i+1] and pAnim == 'confirm' and not pFinished then
            showCover(pTag, i, true)
        else
            if pFinished or pAnim ~= 'confirm' then
                pHasSustain[i+1] = false
            end
            hideCover(pTag, i, true)
        end

        -- ===== الخصم =====
        if eHasSustain[i+1] and eAnim == 'confirm' and not eFinished then
            showCover(eTag, i, false)
        else
            if eFinished or eAnim ~= 'confirm' then
                eHasSustain[i+1] = false
            end
            local eAlpha = getProperty(eTag..'.alpha')
            if eAlpha > 0.01 then
                setProperty(eTag..'.alpha', math.max(0.0001, eAlpha - elapsed * 10))
                if getProperty(eTag..'.alpha') <= 0.01 then
                    eActive[i+1]          = false
                    rgbApplied.enemy[i+1] = false
                end
            end
        end
    end
end

-- ===================== POSITION =====================

function updatePos(tag, strum)
    if isPixelStage then
        setGraphicSize(tag, getProperty(strum..'.width') * 1.4)
        updateHitbox(tag)
        setProperty(tag..'.x', getProperty(strum..'.x') - (getProperty(tag..'.width')  / 6))
        setProperty(tag..'.y', getProperty(strum..'.y') - (getProperty(tag..'.height') / 4))
    else
        scaleObject(tag, 1, 1)
        updateHitbox(tag)
        setProperty(tag..'.x', getProperty(strum..'.x') - 110)
        setProperty(tag..'.y', getProperty(strum..'.y') - 100)
    end
end

-- ===================== RGB SHADER =====================

function applyRGB(tag, id, isPlayer)
    local p   = isPlayer and 'true' or 'false'
    local ids = tostring(id)
    runHaxeCode(
        'var cover = game.modchartSprites.get("' .. tag .. '");'
     .. 'var strum = ' .. p
     ..     ' ? game.playerStrums.members['   .. ids .. ']'
     ..     ' : game.opponentStrums.members[' .. ids .. '];'
     .. 'if (cover != null && strum != null) {'
     ..     'if (cover.shader == null && strum.shader != null)'
     ..         ' cover.shader = strum.shader;'
     ..     'if (cover.rgbShader != null && strum.rgbShader != null) {'
     ..         'cover.rgbShader.parent.r = strum.rgbShader.parent.r;'
     ..         'cover.rgbShader.parent.g = strum.rgbShader.parent.g;'
     ..         'cover.rgbShader.parent.b = strum.rgbShader.parent.b;'
     ..     '} else { cover.color = strum.color; }'
     .. '}'
    )
end

-- ===================== TIMER =====================

function onTimerCompleted(tag)
    if tag:sub(1, 5) == 'fadeP' then
        local dir = tonumber(tag:sub(6))
        if dir ~= nil then
            setProperty(playerCovers[dir+1]..'.alpha', 0.0001)
            rgbApplied.player[dir+1] = false
        end
    end
end
