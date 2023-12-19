import { Router, Request, Response } from "express";
import { synonyms } from "../utils/dataStore";

const router = Router();

router.post("/", (req: Request, res: Response) => {
  const words: string[] | undefined = req.body?.words;

  //TODO add a seprate check with diffrent error for words undefined
  if (!words || words.length < 2) {
    return res
      .status(400)
      .json({ error: "To few words to add needs at least 2" });
  }

  //TODO add check if any word is an empty string or not string

  //TODO add check if the same word appers twice

  try {
    synonyms.add(words);
    return res.status(201).json({ message: "Succesfully added synonym" });
  } catch (error) {
    console.error(error);
    //TODO Security Don't return full error in production
    return res.status(500).json({ error: error });
  }
});

export default router;
