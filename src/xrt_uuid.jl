using .XRTWrap: UUID

Base.show(io::IO, uuid::XRTWrap.UUID) = print(io, "$(XRTWrap.string(uuid))")

Base.:(==)(uuid1::XRTWrap.UUID, uuid2::XRTWrap.UUID) = string(uuid1) == string(uuid2)
