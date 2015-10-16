# lua-HAProxy

First steps in using lua to update HAProxy for a DOCKER SNI configuration

### Lua
- penlight
 - template
 - text
- socket
- socket.unix
- json

### Alpine
Used as Dockerbase for development and I'll use it for the 'final' image.

### it's a work in progress
> so don't shoot me

Whats working:
- getting /containers/json
- getting /containers/xxxidxxxid/json (probably not needed for my configuration)j
- filling in a haproxy.tmpl
  using `>` for lua code and `$(var)` for text replace 

I've made my own http lib over socket.unix. This is an intermediate step, next step whould be to use the existing http lib over socket.unix
