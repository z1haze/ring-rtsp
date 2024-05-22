require('dotenv').config();

import fs from 'fs';
import RtspServer from "rtsp-streaming-server";
import {RingApi, RingCamera} from 'ring-client-api';
import {StreamOptions} from './types';
import streamOptionsData from './streams.json';

const streamOptions: StreamOptions[] = streamOptionsData;

const ringApi = new RingApi({
  refreshToken: process.env.RING_TOKEN as string,
  cameraStatusPollingSeconds: 20
});

ringApi.onRefreshTokenUpdated.subscribe(async ({newRefreshToken, oldRefreshToken}) => {
    if (oldRefreshToken) {
      const currentConfig = await fs.promises.readFile('.env', 'utf-8');
      const updatedConfig = currentConfig.replace(oldRefreshToken!, newRefreshToken);

      await fs.promises.writeFile('.env', updatedConfig);
    }
  }
);

const startRTSPStream = (camera: RingCamera, streamOptions: StreamOptions) => {
  const streamUrl = `${process.env.RTSP_URL}:${process.env.RTSP_SERVER_PORT}/camera_${camera.id}_${streamOptions.name}`;

  console.log(`Starting RTSP video stream of camera ${camera.id} to ${streamUrl}`);

  camera.streamVideo({
    output: [
      '-f', 'rtsp',
      '-c:a', 'copy',
      '-preset', 'veryfast',
      '-tune', 'zerolatency',
      '-pix_fmt', 'yuv420p',
      ...streamOptions.output,
      streamUrl,
    ],
  })
    .then(streamSession => {
      const startedAt = Date.now();
      console.log('Stream session started...');

      streamSession.onCallEnded.subscribe(() => {
        console.log('Ring call lasted ' + ((Date.now() - startedAt) / 1000) + 's.');

        setTimeout(() => {
          startRTSPStream(camera, streamOptions);
        }, 1000 * 10);
      });
    });
}

const server = new RtspServer({
  serverPort: process.env.RTSP_SERVER_PORT as unknown as number,
  clientPort: process.env.RTSP_CLIENT_PORT as unknown as number,
  rtpPortStart: 10000,
  rtpPortCount: 10000
});

server.start()
  .then(() => {
    ringApi.getCameras().then(cameras => {
      console.log(`Found ${cameras.length} camera(s).`);

      for (let camera of cameras) {
        streamOptions.forEach(streamOptions =>
          startRTSPStream(camera, streamOptions));
      }
    });
  });