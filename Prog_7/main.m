close all;
clear all;
clc;

% Chunk 16 bytes
fileName='test_image.jpg';
[imageName,format] = strtok(fileName, '.');
format=format(2:end);
lengthChunk=4;
key=5;
modulo = (2^32);
host = '192.168.43.143';
port = 8081;
lengthKey=8;
funType='xor';
cryptType='rngA';
nIt = 8;

% charKey=dec2bin(key,8);
fprintf('\nStart....\n');
fileIDImage=fopen(fileName);
bytesStream=fread(fileIDImage,'uint32');
fclose(fileIDImage);

nChunk=floor(length(bytesStream))
% uint32 dim;
% dim = dec2bin(nChunk,32);

% tcp_com = tcpip(host, port, 'NetworkRole' ,'client');
% fopen(tcp_com);
% fprintf("n° chunk -----> %d\n", a);
% fwrite(tcp_com, nChunk, 'uint32');

chunkStream=reshape(bytesStream(1:nChunk),[1 nChunk]);
bitsStream=dec2bin(bytesStream);

cryptedChunkStream=zeros(size(chunkStream));
for i=1 : size(chunkStream,2)
    crp = mod((chunkStream(i)*key),modulo);
    cryptedChunkStream(i) = crp;
end

% ###########################################################################

import java.net.*;
import java.io.*;

% primo invio stream criptato
output_socket = [];
try
    fprintf("dim: %d\n", nChunk);
    fprintf("\nTry to connect to host with port %d\n------------->\n", port);

    out_socket = Socket(host,port);
    fprintf("\nConnesso a %s\n", host);

    % mando il criptato a B
    output_socket = out_socket.getOutputStream;
    d_output_stream = DataOutputStream(output_socket);

    d_output_stream.writeInt(nChunk);

    fprintf("\nInvio dim-----> %d\n", nChunk);
    d_output_stream.write(cryptedChunkStream, 0, nChunk);
    d_output_stream.flush;

catch
    if ~isempty(out_socket)
        out_socket.close;
    end
end

% ricezione stream, decript, reinvio stream
msg = [];
output_socket = [];
try
    fprintf("\nTry to connect to host with port_2 %d\n<-------------", port);
    fprintf("\n...Connected with host...\n");

    input_stream = output_socket.getInputStream;
    d_input_stream = DataInputStream(input_stream);

    %lettura da socket, se non va fai un ciclo e prendi byte per
    %byte e mettili in una riga di zeri: [msg = zeros(1, bytes_available, 'uint32')]
    bytes_available = input_stream.available;
    data_reader = DataReader(d_input_stream);
    msg = data_reader.readBuffer(bytes_available);

    %nChunk=floor(length(msg));
    chunkStream=reshape(msg(1:nChunk),[1 nChunk]);
    bitsStream=dec2bin(mag);

    % START euclidian-algorithm
    [d, q, a, b, f] = extendedEuclidean_forward(modulo,key); 
    [x, y] = extendedEuclidean_backSubstitution (d, q, a, b, f);
    if (x < 0)
        decr = mod + x;
    else
        decr = x;
    end
    fprintf("\nThis is my decription-key: %d\n", decr);
    % END euclidian-algorithm and return 'decr'

    decryptedChunkStream=zeros(size(chunkStream));
    for i=1 : size(chunkStream,2)
        crp = mod((chunkStream(i)*decr),modulo);
        decryptedChunkStream(i) = crp;
    end
    d_output_stream.write(decryptedChunkStream, 0, nChunk);
    d_output_stream.flush;
catch
    if ~isempty(output_socket)
        output_socket.close
    end
end
        
% ###########################################################################

%fwrite(tcp_com, cryptedChunkStream);

fprintf('\nEnd.....\n');

%% euclidian algorithm for decrypption-key
key = (2^29)-1;
mod = (2^32);
[d, q, a, b, f] = extendedEuclidean_forward(mod,key); 
[x, y] = extendedEuclidean_backSubstitution(d, q, a, b, f);
if (x < 0)
    decr = mod + x;
else
    decr = x;
end
fprintf("This is my decription-key: %d\n", decr);

%% data read

% tcp_rcv_com = tcpip(host, port, 'NetworkRole', 'server');
% fopen(tcp_rcv_com);
% 
% n_chunk_rcv = fread(tcp_rcv_com, 1, 'uint32');
% msg = fread(tcp_rcv_com, (n_chunk_rcv), 'uint32'); 
% msg = char(msg_byte);

msg = [];
msg = socket_BA(host, port, 10);

nChunk=floor(length(msg));
uint32 dim_d;
dim_d = dec2bin(nChunk,32);
% verificare la disposizione in colonna o riga della roba che ti manda
% lorpi
chunkStream=reshape(msg(1:nChunk),[1 nChunk]);
bitsStream=dec2bin(mag);

decryptedChunkStream=zeros(size(chunkStream));
for i=1 : size(chunkStream,2)
    crp = mod((chunkStream(i)*decr),(2^32));
    decryptedChunkStream(i) = crp;
end

socket_AB(host, port, 10, dim_d, decryptedChunkStream);

% tcp_reinv_com = tcpip(host, port, 'NetworkRole', 'client');
% fopen(tcp_reinv_com);
% fwrite(tcp_reinv_com, decryptedChunkStream);