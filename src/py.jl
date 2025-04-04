# https://discourse.julialang.org/t/avoiding-module-init-being-called-multiple-times/83298
struct PyLazyObj
    py::Py
    _path::String
end

PyLazyObj(path::String) = PyLazyObj(pynew(), path)

pyimport!(x::PyLazyObj) = pycopy!(x.py, pyimport(x._path))
Base.isassigned(x::PyLazyObj) = !pyisnull(x.py)
PythonCall.Py(x::PyLazyObj) = getfield(x, :py)

function Base.getproperty(x::PyLazyObj, s::Symbol)
    if s in fieldnames(PyLazyObj)
        return getfield(x, s)
    else
        !isassigned(x) && pyimport!(x)
        return getproperty(Py(x), s)
    end
end