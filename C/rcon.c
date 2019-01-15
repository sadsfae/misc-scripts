#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <getopt.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#define PROBE_HEADER "\xFF\xFF\xFF\xFF"
#define RCON_PROBE_HEADER PROBE_HEADER "rcon"

#define MAX_SR_LINE 1024
static char srline[MAX_SR_LINE]; 

static struct option long_options[] = {
    { .name = "help", .has_arg = 0, .val = 'h' },
    { .name = "rcon", .has_arg = 1, .val = 'r' },
    { 0 }
};

typedef enum {
    RC_INVALID_IP = 1,
    RC_NO_IP,
    RC_INVALID_PORT,
    RC_NO_PORT,
    RC_INVALID_PW,
    RC_NO_PW,
    RC_INVALID_CMD,
    RC_NO_CMD,
    RC_SET_TIMEVAL,
    RC_RECV
} errorcode_t;

static void printError(int rc)
{
    switch(rc) {
    case RC_INVALID_IP:
        printf("Invalid IP address specified.\n");
        break;
    case RC_NO_IP:
        printf("No IP address specified.\n");
        break;
    case RC_INVALID_PORT:
        printf("Invalid port address specified.\n");
        break;
    case RC_NO_PORT:
        printf("No port address specified.\n");
        break;
    case RC_NO_PW:
        printf("No rconpw specified.\n");
        break;
    case RC_NO_CMD:
        printf("No command specified.\n");
        break;
    case RC_SET_TIMEVAL:
        printf("Could not set timeval on socket\n");
        break;
    case RC_RECV:
        printf("Could not receive.\n");
        break;
    default:
        printf("Unkown errorcode.\n");
    }
}

static int ParseOptionArguments(char *args, char **ip, int *port, char **pw, char **cmd)
{
    char *ptr;
    struct sockaddr_in sa;
    
    ptr = strtok(args, " :"); // ip
    if(!ptr)
        return RC_NO_IP;
    if(inet_pton(AF_INET, ptr, &(sa.sin_addr)) < 1) {
        return RC_INVALID_IP;
    }
    *ip = ptr;

    ptr = strtok(NULL, " :"); // port
    if(!ptr)
        return RC_NO_PORT;
    *port = strtol(ptr, NULL, 0);
    if(*port < 1024 || *port > 65535) {
        return RC_INVALID_PORT;
    }
    
    ptr = strtok(NULL, " :"); // pw
    if(!ptr)
        return RC_NO_PW;
    *pw = ptr;

    ptr = strtok(NULL, ""); // cmd
    if(!ptr)
        return RC_NO_CMD;
    *cmd = ptr;

    return 0;
}

static int Rcon(char *args)
{
    char *ip, *rconpw, *cmd;
    int port, sockfd, n, rc;
    struct sockaddr_in servaddr;
    struct timeval tv = {
        .tv_sec = 3, .tv_usec = 0
    };

    rc = ParseOptionArguments(args, &ip, &port, &rconpw, &cmd);
    if(rc)
        return rc;

    snprintf(srline, MAX_SR_LINE, "%s %s %s",
        RCON_PROBE_HEADER, rconpw, cmd);

    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    memset(&servaddr, 0, sizeof(servaddr));
    servaddr.sin_family = AF_INET;
    servaddr.sin_addr.s_addr = inet_addr(ip);
    servaddr.sin_port = htons(port);

    printf("Sending:\n%s\n\n", srline);

    sendto(sockfd, srline, strlen(srline), 0, (struct sockaddr *)&servaddr, sizeof(servaddr));

    if (setsockopt(sockfd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv)) < 0) {
        close(sockfd);
        return RC_SET_TIMEVAL;
    }

    n = recvfrom(sockfd, srline, MAX_SR_LINE, 0, NULL, NULL);
    if(n < 0) {
        close(sockfd);
        return RC_RECV;
    }
    srline[n] = 0;

    printf("Receiving:\n%s\n", srline);

    close(sockfd);
    return 0;
}

static void Help( void )
{
    printf("Usage: <programname> --rcon=\"<ip> <port> <rconpw> <cmd>\"\n"
            "Example: --rcon=\"127.0.0.1 27960 myrconpw devmap oasis\"\n");
}

int main(int argc, char *argv[])
{
    int opt, rc;
    while (1) {
        opt = getopt_long(argc, argv, "r:h", long_options, NULL);
        if (opt == -1)
            break;

        switch (opt) {
        case 'r':
            rc = Rcon(optarg);
            if(rc) {
                printError(rc);
                return rc;
            }
            break;
        case 'h':
            Help();
            break;
        default:
            return 1;
        }
    }
    return 0;
}
