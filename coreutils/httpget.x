module main

// httpget <url> [-o file] — minimal HTTP/1.1 GET client (mini wget/curl).
//
// Pure xlang. Parses http://host:port/path (port defaults to 80), opens a TCP
// connection via tcp_connect, sends `GET <path> HTTP/1.1` with
// `Connection: close`, receives the response (binary-safe via recv_n), strips
// the headers, and writes the body to stdout — or to <file> with -o.
//
// Connection: close means the server closes after the response, so we read to
// EOF and don't need Content-Length framing. Text bodies (HTML/JSON/CSS/JS/API)
// are printed/saved faithfully; binary bodies containing NUL bytes are truncated
// by the C-string accumulation (print_raw/write_file are strlen-based) — same
// model limitation as the proxy's request forward.

struct Url {
    host: String
    port: i32
    path: String
}

// Parse "http://host:port/path" (or "host/path", "host:port") into host/port/path.
fn parse_url(url: String): Url {
    let mut rest: String = url
    if str_starts_with(url, "http://") {
        rest = str_slice(url, 7, str_len(url))
    }
    let slash: i32 = str_find(rest, "/")
    let mut hostport: String = rest
    let mut path: String = "/"
    if slash >= 0 {
        hostport = str_slice(rest, 0, slash)
        path = str_slice(rest, slash, str_len(rest))
    }
    let mut host: String = hostport
    let mut port: i32 = 80
    let colon: i32 = str_find(hostport, ":")
    if colon >= 0 {
        host = str_slice(hostport, 0, colon)
        port = str_to_int(str_slice(hostport, colon + 1, str_len(hostport)))
    }
    return Url { host: host, port: port, path: path }
}

fn main(): i32 {
    if argc() < 2 {
        print_str("usage: httpget <url> [-o file]")
        return 1
    }
    let u: Url = parse_url(argv(1))
    let mut outfile: String = ""
    if argc() >= 4 {
        if str_eq(argv(2), "-o") {
            outfile = argv(3)
        }
    }

    let sock: i32 = tcp_connect(u.host, u.port)
    if sock < 0 {
        print_str("httpget: connection failed")
        return 1
    }

    // Build + send the request.
    sb_new()
    sb_push("GET ")
    sb_push(u.path)
    sb_push(" HTTP/1.1\r\nHost: ")
    sb_push(u.host)
    sb_push("\r\nConnection: close\r\nUser-Agent: xlang-httpget/1.0\r\n\r\n")
    send_str(sock, sb_str())

    // Receive the whole response (Connection: close => read to EOF), tracking
    // where the headers end (\r\n\r\n) so we can slice the body out.
    sb_new()
    let mut hdrend: i32 = -1
    while true {
        let n: i32 = recv_n(sock)
        if n == 0 { break }
        sb_push(rbuf_str())
        if hdrend < 0 {
            let buf: String = sb_str()
            let he: i32 = str_find(buf, "\r\n\r\n")
            if he >= 0 { hdrend = he + 4 }
        }
    }
    close_fd(sock)

    let full: String = sb_str()
    if hdrend < 0 { hdrend = 0 }
    let body: String = str_slice(full, hdrend, str_len(full))

    if str_len(outfile) > 0 {
        write_file(outfile, body)
    } else {
        print_raw(body)
    }
    return 0
}
