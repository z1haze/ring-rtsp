import {toKebabCase} from "./util";

require('dotenv').config();

import fs from 'fs';
import RtspServer from "rtsp-streaming-server";
import {RingApi, RingCamera} from 'ring-client-api';

const ringApi = new RingApi({
  refreshToken: process.env.RING_TOKEN as string,
  cameraStatusPollingSeconds: 20,
  debug: true
});

ringApi.onRefreshTokenUpdated.subscribe(async ({newRefreshToken, oldRefreshToken}) => {
    if (oldRefreshToken) {
      const currentConfig = await fs.promises.readFile('.env', 'utf-8');
      const updatedConfig = currentConfig.replace(oldRefreshToken!, newRefreshToken);

      await fs.promises.writeFile('.env', updatedConfig);
    }
  }
);

const startRTSPStream = (camera: RingCamera) => {
  const streamUrl = `${process.env.RTSP_URL}:${process.env.RTSP_SERVER_PORT}/${toKebabCase(camera.name) ?? 'cam-' + camera.id}`;

  console.log(`Starting RTSP video stream of camera ${camera.id} to ${streamUrl}`);

  camera.streamVideo({
    output: [
      '-f',
      'rtsp',
      '-c:v',
      'libx264',
      '-preset',
      'ultrafast',
      '-tune',
      'zerolatency',
      '-b',
      `${process.env.VIDEO_BITRATE}`,
      '-filter:v',
      `fps=${process.env.VIDEO_FRAMERATE}`,
      streamUrl,
    ],
  })
    .then(streamSession => {
      const startedAt = Date.now();
      console.log('Stream session started...');

      streamSession.onCallEnded.subscribe(() => {
        console.log('Ring call lasted ' + ((Date.now() - startedAt) / 1000) + 's.');

        setTimeout(() => {
          startRTSPStream(camera);
        }, 1000 * 30);
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
        startRTSPStream(camera);
      }
    });
  });