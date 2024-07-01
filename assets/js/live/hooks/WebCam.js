export default WebCam = {
  getImageSizeFromDataURL(dataURL) {
    // 'base64,' 以降の部分を抽出
    const base64String = dataURL.split(',')[1];
  
    // Base64文字列の長さを取得
    const base64Length = base64String.length;
  
    // パディングの '=' を除外
    const padding = (base64String.match(/=+$/) || [''])[0].length;
  
    // byte数を計算
    // Base64は1文字6bit
    // byteで計算するために4文字3byte(24bit)で考える
    const byteSize = (base64Length * 3 / 4) - padding;
  
    return byteSize;
  },
  getDefaultVideoDimensions() {
    // mobile browser で縦表示の場合、video タグの width と height の値が逆に設定され表示が崩れてしまう。
    // 上記問題を回避するために、縦横各表示に合わせた値を返却する。
    return {
      width: { ideal: screen.availHeight > screen.availWidth ? 240 : 320 },
      height: { ideal: screen.availHeight > screen.availWidth ? 320 : 240 },
    };
  },
  setSendInterval() {
    const webcamVideo = document.querySelector("#webcam-video");
    const webcamCaptureCanvas = document.querySelector("#webcam-capture-canvas");
    // サーバーへ画像を送信
    return setInterval(() => {
      if (webcamVideo.paused) return;
      const dataURL = webcamCaptureCanvas.toDataURL("image/jpeg", this.imageQuality);
      this.pushEvent("send_image_to_mec", { image: dataURL });
      this.pushEvent("send_image_to_cloud", { image: dataURL });
    }, 1000 / this.fps);
  },
  mounted() {
    // WebCam
    const webcamVideo = document.querySelector("#webcam-video");
    const webcamCaptureCanvas = document.querySelector("#webcam-capture-canvas");
    const webcamCaptureContext = webcamCaptureCanvas.getContext("2d");
    const returnedMecImage = new Image();
    const returnedCloudImage = new Image();
    const returnFromMecCanvas = document.querySelector("#return-from-mec-canvas");
    const returnFromMecContext = returnFromMecCanvas.getContext("2d");
    const returnFromCloudCanvas = document.querySelector("#return-from-cloud-canvas");
    const returnFromCloudContext = returnFromCloudCanvas.getContext("2d");

    this.fps = Number(this.el.dataset.fps);
    this.imageQuality = Number(this.el.dataset.imageQuality);

    navigator.mediaDevices.getUserMedia({ 
      video: {
        facingMode: "user",
        frameRate: { ideal: this.fps },
        ...this.getDefaultVideoDimensions()
      },
      audio: false 
    })
    .then(stream => {
      webcamVideo.srcObject = stream;
      webcamVideo.play();
      this.track = stream.getVideoTracks()[0];
    })
    .catch(err => {
      console.error("Error accessing webcam: " + err);
    });

    // smartphone の画面回転への対応
    screen.orientation.addEventListener("change", (event) => {
      if (!this.track) return;
      this.track.applyConstraints(this.getDefaultVideoDimensions());
    });
    
    this.handleEvent("update_webcam_settings", ({ fps, image_quality }) => {
      if (!this.track) return;
      this.imageQuality = Number(image_quality);
      fps = Number(fps);
      if (this.fps !== fps) {
        this.fps = fps;
        this.track.applyConstraints({ 
          frameRate: { ideal: this.fps },
          ...this.getDefaultVideoDimensions()
        });
        clearInterval(this.currentSendIntervalID);
        this.currentSendIntervalID = this.setSendInterval();
      }
    });

    // WebCamの画像を描画
    const updateWebcamCaptureCanvas = () => {
      webcamCaptureContext.clearRect(0, 0, webcamCaptureCanvas.width, webcamCaptureCanvas.height);
      webcamCaptureContext.drawImage(webcamVideo, 0, 0, webcamCaptureCanvas.width, webcamCaptureCanvas.height);
      requestAnimationFrame(updateWebcamCaptureCanvas);
    };
    updateWebcamCaptureCanvas();

    // サーバーへ画像を送信
    this.currentSendIntervalID = this.setSendInterval();

    // サーバーから返ってきた画像を描画
    this.handleEvent("mec_returned", ({ returned_image: dataURL, latency }) => {
      returnedMecImage.src = dataURL;
      requestAnimationFrame(() => {
        returnFromMecContext.drawImage(returnedMecImage, 0, 0, returnFromMecCanvas.width, returnFromMecCanvas.height);
        document.querySelector("#mec-latency").innerHTML = latency;
        document.querySelector("#mec-data-size").innerHTML = this.getImageSizeFromDataURL(dataURL);
      });
    });

    // サーバーから返ってきた画像を描画
    this.handleEvent("cloud_returned", ({ returned_image: dataURL, latency }) => {
      returnedCloudImage.src = dataURL;
      requestAnimationFrame(() => {
        returnFromCloudContext.drawImage(returnedCloudImage, 0, 0, returnFromCloudCanvas.width, returnFromCloudCanvas.height);
        document.querySelector("#cloud-latency").innerHTML = latency;
        document.querySelector("#cloud-data-size").innerHTML = this.getImageSizeFromDataURL(dataURL);
      });
    });
  }
};
