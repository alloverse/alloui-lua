local modules = (...):gsub('%.[^%.]+$', '') .. "."


return {
    View = require(modules.."views.view"),
    Surface = require(modules.."views.surface"),
    VideoSurface = require(modules.."views.videosurface"),
    Cube = require(modules.."views.cube"),
    NavStack = require(modules.."views.navstack"),
    Button = require(modules.."views.button"),
    Slider = require(modules.."views.slider"),
    Label = require(modules.."views.label"),
    TextField = require(modules.."views.text_field"),
    GrabHandle = require(modules.."views.grab_handle"),
    ResizeHandle = require(modules.."views.resize_handle"),
    Speaker = require(modules.."views.speaker"),
    GridView = require(modules.."views.gridview"),
    TabView = require(modules.."views.tabview"),
    ModelView = require(modules.."views.modelview"),
    StackView = require(modules.."views.stackview"),
    ProxyIconView = require(modules.."views.proxy_icon"),
    FrameView = require(modules.."views.frameview"),
    Ninepatch = require(modules.."views.ninepatch"),
    Bounds = require(modules.."bounds"),
    Pose = require(modules.."pose"),
    App = require(modules.."app"),
    Color = require(modules.."color"),
    Size = require(modules.."size"),
    util = require(modules.."util"),
    Asset = require(modules.."asset.init"),
    PropertyAnimation = require(modules.."property_animation"),
    StandardAnimations = require(modules.."standard_animations")
    
}
