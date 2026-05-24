import { Router, type IRouter } from "express";
import healthRouter from "./health";
import storageRouter from "./storage";
import certificatesRouter from "./certificates";
import leanRouter from "./lean";

const router: IRouter = Router();

router.use(healthRouter);
router.use(storageRouter);
router.use(certificatesRouter);
router.use(leanRouter);

export default router;
