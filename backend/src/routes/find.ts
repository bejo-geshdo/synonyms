import { Router, Request, Response } from "express";

import { synonyms } from "../utils/dataStore";

const router = Router();

router.get("/", (req: Request, res: Response) => {
  const word = req.query?.word;

  if (typeof word !== "string") {
    return res.status(400).json({ error: "Missing word in query" });
  }

  const words = synonyms.findAllSynonyms(word);

  if (words.length < 2) {
    return res.status(404).json({ error: `No synonyms found for ${word}` });
  }

  return res.status(200).json({ message: words });
});

export default router;
