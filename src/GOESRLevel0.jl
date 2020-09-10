module GOESRLevel0

using Reexport

include("Rice/Rice.jl")
@reexport using .Rice

"""
Descibes the type of the scene

| name           | value  | Description                              |
|:-------------- |:------ |:---------------------------------------- |
| `disk`         | `0x00` | Whole visible disk                       |
| `conus`        | `0x01` | CONUS region                             |
| `meso1`        | `0x02` | Meso 1 region                            |
| `meso2`        | `0x03` | Meso 2 region                            |
| `starlook_vis` | `0x05` | VIS starlook calibration                 |
| `starlook_ir`  | `0x0a` | IR starlook calibration                  |
| `cal_ir`       | `0x0b` | IR calibration (black body calibration?) |
| `spacelook`    | `0x0d` | space look calibration                   |

"""
@enum SceneType::UInt8 begin
    disk = 0x00
    conus = 0x01
    meso1 = 0x02
    meso2 = 0x03
    starlook_vis = 0x05
    starlook_ir = 0x0a
    cal_ir = 0x0b
    spacelook = 0x0d
end

export SceneType

end # module
