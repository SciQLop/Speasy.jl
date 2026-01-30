module SpeasyUnitfulExt
using Unitful: uparse
import Unitful: Unitful, unit
using Speasy: AbstractDataContainer, units

function _unit(str)
    try
        return uparse(str)
    catch
    end
    try # replace space by *
        str = replace(str, " " => "*", "{" => "", "}" => "", "#" => "1", "sec" => "s", "cm3" => "cm^3", "cc" => "cm^3")
        return uparse(str)
    catch
    end
    try # split str by space
        return uparse(split(str, " ")[1])
    catch
    end

    @info "Cannot parse $(name(var)) unit $str"
    return 1
end

function Unitful.unit(var::AbstractDataContainer)
    return _unit(units(var))
end

end
