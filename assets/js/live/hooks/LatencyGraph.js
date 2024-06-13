import Plotly from "../../../vendor/plotly-2.33.0.min";

export default LatencyGraph = {
  createTrace(name) {
    return {
      x: [],
      y: [],
      mode: "lines",
      type: "scatter",
      hovertemplate: "%{y} ms",
      name
    };
  },
  createLayout() {
    return {
      title: "Latency",
      hovermode: "x unified",
      dragmode: false,
      xaxis: {
        rangemode: "tozero"
      },
      legend: {
        orientation: "h",
      },
      margin: {
        l: 30,
        r: 30,
      }
    };
  },
  createConfig() {
    return {
      displayModeBar: false,
      responsive: true
    };
  },
  updateTrace(trace, latency, traceIndex) {
    trace.x = trace.x.map((x) => x - 1);
    trace.x.push(0);
    trace.y.push(latency);

    if (trace.x.length > this.maxDataSize) {
      trace.x.shift();
      trace.y.shift();
    }

    Plotly.update(this.graphDivID, { x: [trace.x], y: [trace.y] }, this.layout, [traceIndex]);
  },
  mounted() {
    this.graphDivID = "latency-graph";
    this.maxDataSize = 101;
    this.mecTrace = this.createTrace("MEC");
    this.cloudTrace = this.createTrace("Cloud");
    this.layout = this.createLayout();
    this.config = this.createConfig();

    Plotly.newPlot(this.graphDivID, [this.mecTrace, this.cloudTrace], this.layout, this.config);

    this.handleEvent("mec_returned", ({ latency }) => {
      this.updateTrace(this.mecTrace, latency, 0);
    });

    this.handleEvent("cloud_returned", ({ latency }) => {
      this.updateTrace(this.cloudTrace, latency, 1);
    });
  },
  updated() {
    Plotly.newPlot(this.graphDivID, [this.mecTrace, this.cloudTrace], this.layout, this.config);
  }
};
