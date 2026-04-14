import express from "express";
import cors from "cors";
import * as functions from "firebase-functions";

const app = express();

app.use(cors({ origin: true }));
app.use(express.json());

// example route
app.get("/", (req, res) => {
  res.send("Hello from Firebase Functions!");
});

export const api = functions.https.onRequest(app);