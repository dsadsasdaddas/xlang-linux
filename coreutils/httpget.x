module main

// httpget <url> [-o file] — minimal HTTP/1.1 GET client (mini wget/curl).
//
// Pure xlang. Parses http://host:port/path (port defaults to 80), opens a TCP
// connection via tcp_connect, sends `GET <path> HTTP/1.1` with
// `Connection: close`, receives the response (binary-safe via recv_n), strips
// the headers, and writes the body to stdout — or to <file> with -o.
//
// Connection: close means the server closes after the response, so we read to
// EOF and don't need Content-Length framing. The body is streamed BINARY-SAFE
// (write_rbuf = write(2), NUL bytes preserved) — images / compressed / arbitrary
// binary download byte-identical to stdout or -o file.

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

    // Stream the response body BINARY-SAFE to the output fd (stdout or -o file).
    // Real HTTP headers are tiny (< one 64 KB chunk), so the first recv holds
    // them: find \r\n\r\n there and write the body tail of that chunk, then write
    // every later chunk raw, via write_rbuf (write(2), NUL-safe). Downloads
    // images / compressed / arbitrary binary byte-identical.
    let mut out_fd: i32 = 1
    if str_len(outfile) > 0 {
        out_fd = open_write(outfile)
    }
    let mut header_done: i32 = 0
    while true {
        let n: i32 = recv_n(sock)
        if n == 0 { break }
        if header_done == 0 {
            let he: i32 = str_find(rbuf_str(), "\r\n\r\n")
            if he >= 0 {
                header_done = 1
                let hdrlen: i32 = he + 4
                let body_in_chunk: i32 = n - hdrlen
                if body_in_chunk > 0 {
                    write_rbuf(out_fd, hdrlen, body_in_chunk)
                }
            }
            // else: headers span past this chunk (pathological >64KB headers);
            // not handled — real HTTP headers always fit in the first chunk.
        } else {
            write_rbuf(out_fd, 0, n)
        }
    }
    close_fd(sock)
    if out_fd != 1 {
        close_fd(out_fd)
    }
    return 0
}
