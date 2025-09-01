isa_ssl_cert_error(e) = occursin("Caused by SSLError(SSLCertVerificationError", string(e))

function fix_ssl_cert!()
    cert_file = NetworkOptions.system_ca_roots()
    @warn "SSL certificate error detected. Setting SSL_CERT_FILE to $cert_file"
    ENV["SSL_CERT_FILE"] = cert_file
    return
end
