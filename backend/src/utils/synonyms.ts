export class SynonymsService {
  private roots: { [key: string]: string }; // Key-value pairs of word: root-word

  constructor() {
    this.roots = {};
  }

  areSynonyms(word: string, synonym: string): boolean {
    if (this.find(word) === undefined || this.find(synonym) === undefined) {
      return false; // One or both words do not exist in set
    }
    return this.find(word) === this.find(synonym);
  }

  add(synonyms: string[]): boolean {
    if (synonyms.length < 2) {
      return false;
    }
    synonyms.map((synonym) => {
      this.makeSet(synonym);
      this.union(synonyms[0], synonym);
    });
    return true;
  }

  private makeSet(word: string): void {
    if (this.roots[word] === undefined) {
      this.roots[word] = word;
    }
  }

  private find(word: string): string | undefined {
    if (this.roots[word] === undefined) return undefined;

    /**
     * The following line handles path compression.
     * It makes every node in the path point to the root, or parent, string.
     * This is done to speed up future find operations.
     */

    // If this word isn't the parent of its group...
    if (this.roots[word] !== word) {
      // ...find the parent, and then...
      this.roots[word] = this.find(this.roots[word])!;
      // ...directly connect this word to the parent.
    }
    // Now, this word is directly connected to the parent.
    // Next time we want to find its parent, it's just one step away!
    return this.roots[word];
  }

  private union(word: string, synonym: string): void {
    const wordRoot = this.find(word);
    const synonymRoot = this.find(synonym);

    //Check to make sure the Root are not undefined
    if (wordRoot === undefined || synonymRoot === undefined) {
      console.log("One or both elements are not initialized!");
      return;
    }

    if (wordRoot !== synonymRoot) {
      // Only merge if they are in different sets
      this.roots[synonymRoot] = wordRoot;
    }
  }

  findAllSynonyms(word: string): string[] {
    const synonyms: string[] = [];
    const wordRoot = this.find(word);

    if (wordRoot === undefined) {
      return synonyms; // Word not found
    }

    for (const word in this.roots) {
      const rootOfCurrentWord = this.find(word);
      if (rootOfCurrentWord === wordRoot) {
        synonyms.push(word);
      }
    }

    return synonyms;
  }
}
